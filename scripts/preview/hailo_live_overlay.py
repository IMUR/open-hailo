#!/usr/bin/env python3
"""
Live camera preview with Hailo-8 object detection overlays
Works without Frigate - direct Hailo inference with bounding boxes
"""

import sys
import time
import numpy as np
from pathlib import Path
from datetime import datetime
from threading import Thread, Lock
import queue

# Try OpenCV first, fall back to PIL
try:
    import cv2
    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False
    from PIL import Image, ImageDraw, ImageFont
    print("OpenCV not found, using PIL for overlays")

from picamera2 import Picamera2
from hailo_platform import (
    HEF, HailoStreamInterface, VDevice, InferVStreams, 
    FormatType, HailoSchedulingAlgorithm
)

# YOLO class names for COCO dataset
COCO_NAMES = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
    "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat",
    "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
    "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball",
    "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
    "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
    "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake",
    "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop",
    "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
    "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
]

# Color palette for bounding boxes (BGR for OpenCV, RGB for PIL)
COLORS = [
    (255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0), (255, 0, 255),
    (0, 255, 255), (128, 0, 255), (255, 128, 0), (128, 255, 0), (0, 128, 255)
]


class HailoDetector:
    """Handles Hailo inference and detection processing"""
    
    def __init__(self, model_path, threshold=0.5):
        self.model_path = Path(model_path)
        self.threshold = threshold
        self.hef = None
        self.device = None
        self.network_group = None
        self.input_vstreams_params = None
        self.output_vstreams_params = None
        self.input_shape = None
        
        if not self.model_path.exists():
            raise FileNotFoundError(f"Model not found: {self.model_path}")
        
        self._setup_hailo()
    
    def _setup_hailo(self):
        """Initialize Hailo device and model"""
        print(f"Loading model: {self.model_path}")
        self.hef = HEF(str(self.model_path))
        
        # Setup device
        self.device = VDevice()
        self.network_group = self.device.configure(self.hef)
        self.network_group_params = self.network_group.create_params()
        
        # Get input/output info
        self.input_vstreams_params = self.network_group.make_input_vstream_params(
            FormatType.FLOAT32, quantized=False
        )
        self.output_vstreams_params = self.network_group.make_output_vstream_params(
            FormatType.FLOAT32, quantized=False
        )
        
        # Get input shape (typically [1, 3, 640, 640] for YOLOv8)
        input_vstream_info = self.hef.get_input_vstream_infos()[0]
        self.input_shape = input_vstream_info.shape
        print(f"Model input shape: {self.input_shape}")
        
        # Activate network
        self.network_group.activate(self.network_group_params)
    
    def preprocess(self, image):
        """Preprocess image for YOLO inference"""
        h, w = image.shape[:2]
        
        # Resize to model input size (typically 640x640)
        target_size = self.input_shape[2]  # Assuming square input
        
        if HAS_CV2:
            resized = cv2.resize(image, (target_size, target_size))
            # Convert BGR to RGB
            rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
        else:
            pil_img = Image.fromarray(image)
            resized = pil_img.resize((target_size, target_size))
            rgb = np.array(resized)
        
        # Normalize to [0, 1]
        normalized = rgb.astype(np.float32) / 255.0
        
        # Add batch dimension and transpose to NCHW
        batch = np.expand_dims(normalized, axis=0)
        batch = np.transpose(batch, (0, 3, 1, 2))
        
        return batch, (h, w)
    
    def postprocess(self, outputs, original_shape):
        """Process YOLO outputs to get detections"""
        detections = []
        
        # YOLOv8 output format processing
        # This is simplified - actual format depends on model export
        # Typically: [batch, num_predictions, (x, y, w, h, confidence, class_probs...)]
        
        predictions = outputs[0][0]  # Get first batch
        
        for pred in predictions:
            if len(pred) < 85:  # 4 bbox + 1 obj_conf + 80 classes
                continue
                
            x, y, w, h = pred[:4]
            obj_conf = pred[4]
            class_probs = pred[5:85]
            
            # Get best class
            class_id = np.argmax(class_probs)
            class_conf = class_probs[class_id]
            
            # Combined confidence
            confidence = obj_conf * class_conf
            
            if confidence > self.threshold:
                # Scale coordinates to original image
                oh, ow = original_shape
                scale_y = oh / self.input_shape[2]
                scale_x = ow / self.input_shape[3]
                
                # Convert from center to corner coordinates
                x1 = int((x - w/2) * scale_x)
                y1 = int((y - h/2) * scale_y)
                x2 = int((x + w/2) * scale_x)
                y2 = int((y + h/2) * scale_y)
                
                detections.append({
                    'bbox': (x1, y1, x2, y2),
                    'class_id': int(class_id),
                    'class_name': COCO_NAMES[class_id] if class_id < len(COCO_NAMES) else f"class_{class_id}",
                    'confidence': float(confidence)
                })
        
        return detections
    
    def detect(self, image):
        """Run detection on image"""
        # Preprocess
        input_data, original_shape = self.preprocess(image)
        
        # Run inference
        with InferVStreams(self.network_group, self.input_vstreams_params,
                           self.output_vstreams_params) as infer_pipeline:
            outputs = infer_pipeline.infer(
                {self.input_vstreams_params[0].name: input_data}
            )
        
        # Postprocess
        output_data = outputs[self.output_vstreams_params[0].name]
        detections = self.postprocess(output_data, original_shape)
        
        return detections
    
    def cleanup(self):
        """Clean up Hailo resources"""
        if self.network_group:
            self.network_group.deactivate()


def draw_overlays_cv2(image, detections):
    """Draw detection overlays using OpenCV"""
    for det in detections:
        x1, y1, x2, y2 = det['bbox']
        class_name = det['class_name']
        confidence = det['confidence']
        
        # Get color for this class
        color = COLORS[det['class_id'] % len(COLORS)]
        
        # Draw bounding box
        cv2.rectangle(image, (x1, y1), (x2, y2), color, 2)
        
        # Draw label background
        label = f"{class_name}: {confidence:.2f}"
        label_size, _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
        cv2.rectangle(image, (x1, y1 - label_size[1] - 4), 
                     (x1 + label_size[0], y1), color, -1)
        
        # Draw label text
        cv2.putText(image, label, (x1, y1 - 2), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
    
    # Add FPS and detection count
    fps_text = f"Detections: {len(detections)}"
    cv2.putText(image, fps_text, (10, 30), 
               cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
    
    return image


def draw_overlays_pil(image, detections):
    """Draw detection overlays using PIL"""
    pil_img = Image.fromarray(image)
    draw = ImageDraw.Draw(pil_img)
    
    # Try to load a font, fall back to default
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
    except:
        font = ImageFont.load_default()
    
    for det in detections:
        x1, y1, x2, y2 = det['bbox']
        class_name = det['class_name']
        confidence = det['confidence']
        
        # Get color for this class
        color = COLORS[det['class_id'] % len(COLORS)]
        
        # Draw bounding box
        draw.rectangle([x1, y1, x2, y2], outline=color, width=2)
        
        # Draw label
        label = f"{class_name}: {confidence:.2f}"
        draw.text((x1, y1 - 20), label, fill=color, font=font)
    
    # Add detection count
    draw.text((10, 10), f"Detections: {len(detections)}", 
             fill=(0, 255, 0), font=font)
    
    return np.array(pil_img)


def main():
    """Main application loop"""
    print("╔════════════════════════════════════════════════════════════╗")
    print("║     Hailo-8 Live Detection with Overlays                   ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    
    # Model path - adjust as needed
    model_paths = [
        Path.home() / "yolov8n.hef",
        Path.home() / "yolov8s.hef",
        Path("/usr/share/hailo-models/yolov8s.hef"),
        Path("./yolov8s.hef")
    ]
    
    model_path = None
    for path in model_paths:
        if path.exists():
            model_path = path
            break
    
    if not model_path:
        print("❌ No YOLO model found. Please download a .hef model.")
        print("   Expected locations:")
        for p in model_paths:
            print(f"     - {p}")
        return
    
    print(f"✅ Using model: {model_path}")
    
    # Initialize detector
    try:
        detector = HailoDetector(model_path, threshold=0.5)
    except Exception as e:
        print(f"❌ Failed to initialize Hailo: {e}")
        return
    
    # Initialize camera
    picam2 = Picamera2()
    config = picam2.create_preview_configuration(
        main={"size": (1280, 720)},
        lores={"size": (640, 640)},
        display="lores"
    )
    picam2.configure(config)
    
    print("Starting camera...")
    picam2.start()
    time.sleep(2)  # Let camera warm up
    
    print()
    print("🎯 Detection started!")
    print("   Press Ctrl+C to stop")
    print()
    
    frame_count = 0
    start_time = time.time()
    
    try:
        while True:
            # Capture frame
            frame = picam2.capture_array("main")
            
            # Run detection
            detections = detector.detect(frame)
            
            # Draw overlays
            if HAS_CV2:
                frame_with_overlays = draw_overlays_cv2(frame.copy(), detections)
                
                # Display
                cv2.imshow('Hailo-8 Object Detection', frame_with_overlays)
                
                # Save snapshot on 's' key
                key = cv2.waitKey(1) & 0xFF
                if key == ord('s'):
                    filename = f"detection_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
                    cv2.imwrite(filename, frame_with_overlays)
                    print(f"📸 Saved: {filename}")
                elif key == ord('q'):
                    break
            else:
                frame_with_overlays = draw_overlays_pil(frame, detections)
                # For PIL, just save periodic snapshots
                if frame_count % 30 == 0:  # Every second at 30fps
                    filename = f"detection_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
                    Image.fromarray(frame_with_overlays).save(filename)
                    print(f"📸 Saved: {filename}")
            
            # Calculate FPS
            frame_count += 1
            if frame_count % 30 == 0:
                elapsed = time.time() - start_time
                fps = frame_count / elapsed
                print(f"📊 FPS: {fps:.1f} | Detections: {len(detections)}")
                
                # Print detected objects
                if detections:
                    objects = [d['class_name'] for d in detections]
                    print(f"   Objects: {', '.join(objects)}")
    
    except KeyboardInterrupt:
        print("\n⏹️  Stopping...")
    finally:
        picam2.stop()
        detector.cleanup()
        if HAS_CV2:
            cv2.destroyAllWindows()
        
        print("✅ Cleanup complete")


if __name__ == "__main__":
    main()
