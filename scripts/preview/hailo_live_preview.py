#!/usr/bin/env python3
"""
Hailo-8 Live Camera Preview with YOLOv8 Inference
Direct integration without rpicam-apps or TAPPAS
"""

import sys
import time
import cv2
import numpy as np
from pathlib import Path
from picamera2 import Picamera2, Preview
from threading import Thread, Lock
import queue

# Try to import HailoRT Python bindings
try:
    from hailo_platform import (
        Device, HailoStreamInterface, InferVStreams, ConfigureParams,
        InputVStreamParams, OutputVStreamParams, FormatType
    )
    HAILO_AVAILABLE = True
except ImportError:
    print("Warning: HailoRT Python bindings not available")
    print("Inference will be disabled, showing camera preview only")
    HAILO_AVAILABLE = False

class HailoYOLOv8Detector:
    """YOLOv8 object detector using Hailo-8"""
    
    # COCO class names
    CLASS_NAMES = [
        'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck',
        'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench',
        'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra',
        'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
        'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove',
        'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup',
        'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange',
        'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
        'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
        'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
        'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier',
        'toothbrush'
    ]
    
    def __init__(self, model_path, threshold=0.5):
        self.model_path = Path(model_path)
        self.threshold = threshold
        self.device = None
        self.network_group = None
        self.input_vstreams = None
        self.output_vstreams = None
        
        if HAILO_AVAILABLE:
            self.initialize_hailo()
    
    def initialize_hailo(self):
        """Initialize Hailo device and load model"""
        try:
            # Get available devices
            devices = Device.scan()
            if not devices:
                print("No Hailo devices found!")
                return
            
            # Use first device
            self.device = Device()
            print(f"✓ Hailo device opened: {self.device}")
            
            # Load HEF file
            from hailo_platform import HEF
            hef = HEF(str(self.model_path))
            
            # Configure network
            configure_params = ConfigureParams.create_from_hef(hef, 
                                                              HailoStreamInterface.PCIe)
            self.network_group = self.device.configure(hef, configure_params)[0]
            
            # Setup input/output vstreams
            input_params = InputVStreamParams.make_from_network_group(self.network_group)
            output_params = OutputVStreamParams.make_from_network_group(self.network_group)
            
            self.input_vstreams = InferVStreams.create_input_vstreams(self.network_group, input_params)
            self.output_vstreams = InferVStreams.create_output_vstreams(self.network_group, output_params)
            
            print(f"✓ Model loaded: {self.model_path.name}")
            print(f"  Inputs: {[vs.name for vs in self.input_vstreams]}")
            print(f"  Outputs: {[vs.name for vs in self.output_vstreams]}")
            
        except Exception as e:
            print(f"Failed to initialize Hailo: {e}")
            self.device = None
    
    def preprocess(self, image):
        """Preprocess image for YOLOv8"""
        # Resize to 640x640
        resized = cv2.resize(image, (640, 640))
        # Convert BGR to RGB
        rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
        # Normalize to 0-1
        normalized = rgb.astype(np.float32) / 255.0
        # Add batch dimension
        batched = np.expand_dims(normalized, axis=0)
        return batched
    
    def postprocess(self, outputs, orig_shape):
        """Process YOLOv8 outputs and extract detections"""
        # Simple NMS and detection extraction
        # This is a simplified version - full implementation would need proper NMS
        detections = []
        
        # Parse output tensor (format depends on specific model)
        # This is a placeholder - actual format depends on the HEF output
        if outputs and len(outputs) > 0:
            # Typically YOLOv8 outputs [batch, num_detections, 85] 
            # where 85 = 4 bbox + 1 confidence + 80 classes
            output = outputs[0]
            
            for detection in output:
                confidence = detection[4] if len(detection) > 4 else 0
                if confidence > self.threshold:
                    x, y, w, h = detection[:4]
                    class_scores = detection[5:] if len(detection) > 5 else []
                    if class_scores:
                        class_id = np.argmax(class_scores)
                        class_name = self.CLASS_NAMES[class_id] if class_id < len(self.CLASS_NAMES) else f"class_{class_id}"
                        detections.append({
                            'bbox': [x, y, w, h],
                            'confidence': confidence,
                            'class': class_name
                        })
        
        return detections
    
    def detect(self, image):
        """Run detection on image"""
        if not self.device or not HAILO_AVAILABLE:
            return []
        
        try:
            # Preprocess
            input_data = self.preprocess(image)
            
            # Run inference
            with InferVStreams.create_infer_pipeline(self.input_vstreams, 
                                                    self.output_vstreams) as pipeline:
                input_dict = {self.input_vstreams[0].name: input_data}
                outputs = pipeline.infer(input_dict)
            
            # Postprocess
            output_arrays = [outputs[vs.name] for vs in self.output_vstreams]
            detections = self.postprocess(output_arrays, image.shape[:2])
            
            return detections
            
        except Exception as e:
            print(f"Detection error: {e}")
            return []
    
    def draw_detections(self, image, detections):
        """Draw detection boxes on image"""
        for det in detections:
            x, y, w, h = det['bbox']
            # Scale to image size
            h_img, w_img = image.shape[:2]
            x1 = int(x * w_img / 640)
            y1 = int(y * h_img / 640)
            x2 = int((x + w) * w_img / 640)
            y2 = int((y + h) * h_img / 640)
            
            # Draw box
            color = (0, 255, 0)
            cv2.rectangle(image, (x1, y1), (x2, y2), color, 2)
            
            # Draw label
            label = f"{det['class']}: {det['confidence']:.2f}"
            cv2.putText(image, label, (x1, y1-10), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)
        
        return image
    
    def cleanup(self):
        """Clean up resources"""
        if self.device:
            self.device.release()

class HailoCameraPreview:
    """Live camera preview with Hailo inference"""
    
    def __init__(self, model_path, display_size=(1280, 720)):
        self.model_path = model_path
        self.display_size = display_size
        self.detector = HailoYOLOv8Detector(model_path)
        self.picam2 = None
        self.running = False
        self.frame_queue = queue.Queue(maxsize=2)
        self.result_queue = queue.Queue(maxsize=2)
        
    def camera_thread(self):
        """Camera capture thread"""
        while self.running:
            try:
                # Capture frame
                frame = self.picam2.capture_array("main")
                
                # Put in queue for processing (drop old frames)
                if not self.frame_queue.full():
                    self.frame_queue.put(frame)
                
                time.sleep(0.03)  # ~30 FPS
                
            except Exception as e:
                print(f"Camera error: {e}")
                break
    
    def inference_thread(self):
        """Inference processing thread"""
        while self.running:
            try:
                # Get frame from queue
                frame = self.frame_queue.get(timeout=1)
                
                # Run detection
                detections = self.detector.detect(frame)
                
                # Draw on frame
                if detections:
                    frame = self.detector.draw_detections(frame, detections)
                
                # Put result in display queue
                if not self.result_queue.full():
                    self.result_queue.put(frame)
                
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Inference error: {e}")
    
    def run(self):
        """Main preview loop"""
        try:
            # Initialize camera
            self.picam2 = Picamera2()
            
            # Configure camera
            config = self.picam2.create_preview_configuration(
                main={"size": (1920, 1080), "format": "RGB888"},
                lores={"size": (640, 640), "format": "RGB888"},
                display="main"
            )
            self.picam2.configure(config)
            
            # Start camera
            self.picam2.start()
            print("✓ Camera started")
            
            # Start threads
            self.running = True
            cam_thread = Thread(target=self.camera_thread)
            inf_thread = Thread(target=self.inference_thread) if HAILO_AVAILABLE else None
            
            cam_thread.start()
            if inf_thread:
                inf_thread.start()
                print("✓ Inference thread started")
            
            # Display loop
            print("\nPress 'q' to quit, 's' to save screenshot")
            cv2.namedWindow("Hailo YOLOv8 Preview", cv2.WINDOW_NORMAL)
            cv2.resizeWindow("Hailo YOLOv8 Preview", *self.display_size)
            
            last_frame = None
            while True:
                # Get processed frame or raw frame
                try:
                    frame = self.result_queue.get_nowait()
                    last_frame = frame
                except queue.Empty:
                    if last_frame is not None:
                        frame = last_frame
                    else:
                        frame = self.picam2.capture_array("main")
                
                # Convert RGB to BGR for OpenCV
                if len(frame.shape) == 3 and frame.shape[2] == 3:
                    frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
                
                # Display FPS
                cv2.putText(frame, f"Hailo-8 + YOLOv8", (10, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                
                # Show frame
                cv2.imshow("Hailo YOLOv8 Preview", frame)
                
                # Handle key press
                key = cv2.waitKey(1) & 0xFF
                if key == ord('q'):
                    break
                elif key == ord('s'):
                    filename = f"hailo_capture_{int(time.time())}.jpg"
                    cv2.imwrite(filename, frame)
                    print(f"Saved: {filename}")
            
        except Exception as e:
            print(f"Preview error: {e}")
            
        finally:
            # Cleanup
            self.running = False
            if self.picam2:
                self.picam2.stop()
                self.picam2.close()
            if self.detector:
                self.detector.cleanup()
            cv2.destroyAllWindows()
            print("\n✓ Preview stopped")

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Hailo-8 Live Camera Preview")
    parser.add_argument("--model", default="/home/crtr/Projects/open-hailo/models/yolov8s.hef",
                       help="Path to HEF model file")
    parser.add_argument("--threshold", type=float, default=0.5,
                       help="Detection threshold")
    parser.add_argument("--width", type=int, default=1280,
                       help="Display width")
    parser.add_argument("--height", type=int, default=720,
                       help="Display height")
    
    args = parser.parse_args()
    
    # Check model exists
    model_path = Path(args.model)
    if not model_path.exists():
        print(f"Error: Model not found: {model_path}")
        sys.exit(1)
    
    print("═" * 60)
    print("     Hailo-8 Live Camera Preview with YOLOv8")
    print("═" * 60)
    print(f"Model: {model_path.name}")
    print(f"Display: {args.width}x{args.height}")
    print(f"Threshold: {args.threshold}")
    print("═" * 60)
    
    # Run preview
    preview = HailoCameraPreview(
        model_path=model_path,
        display_size=(args.width, args.height)
    )
    preview.run()

if __name__ == "__main__":
    main()
