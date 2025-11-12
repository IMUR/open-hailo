#!/usr/bin/env python3
"""
Hailo-8 Live Preview WITHOUT OpenCV
Uses PIL for image processing and saves frames with detections
"""

import sys
import time
import numpy as np
from pathlib import Path
from picamera2 import Picamera2
from PIL import Image, ImageDraw, ImageFont
from threading import Thread, Lock
import queue

# Simple Hailo detection simulator (replace with actual Hailo code when available)
class HailoYOLOv8Simple:
    """Simplified YOLOv8 detector for Hailo-8"""
    
    def __init__(self, model_path, threshold=0.5):
        self.model_path = Path(model_path)
        self.threshold = threshold
        print(f"Hailo model: {self.model_path.name}")
        # In real implementation, initialize Hailo here
        
    def detect(self, image_array):
        """Simulate detection - replace with actual Hailo inference"""
        # This is a placeholder - actual implementation would use HailoRT
        # For now, return empty list or dummy detections
        return []

class CameraPreviewNoCv:
    """Camera preview without OpenCV dependency"""
    
    def __init__(self, model_path=None, save_interval=30):
        self.model_path = model_path
        self.save_interval = save_interval  # Save frame every N frames
        self.detector = HailoYOLOv8Simple(model_path) if model_path else None
        self.frame_count = 0
        self.running = False
        
    def draw_text_pil(self, img, text, position, color=(0, 255, 0)):
        """Draw text on PIL image"""
        draw = ImageDraw.Draw(img)
        # Try to use a better font if available
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
        except:
            font = ImageFont.load_default()
        draw.text(position, text, fill=color, font=font)
        return img
    
    def draw_box_pil(self, img, bbox, label, color=(0, 255, 0)):
        """Draw bounding box on PIL image"""
        draw = ImageDraw.Draw(img)
        x1, y1, x2, y2 = bbox
        draw.rectangle([x1, y1, x2, y2], outline=color, width=2)
        self.draw_text_pil(img, label, (x1, y1-25), color)
        return img
    
    def process_frame(self, frame_array):
        """Process a frame and add overlays"""
        # Convert to PIL
        img = Image.fromarray(frame_array)
        
        # Add timestamp and info
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        info_text = f"Hailo-8 Preview | Frame: {self.frame_count} | {timestamp}"
        img = self.draw_text_pil(img, info_text, (10, 10))
        
        # Run detection if available
        if self.detector:
            detections = self.detector.detect(frame_array)
            for det in detections:
                # Draw detection boxes
                pass  # Implementation would draw boxes here
        
        return img
    
    def run(self):
        """Main preview loop"""
        print("═" * 60)
        print("     Hailo-8 Camera Preview (No OpenCV)")
        print("═" * 60)
        
        try:
            # Initialize camera
            picam2 = Picamera2()
            
            # Configure
            config = picam2.create_preview_configuration(
                main={"size": (1920, 1080), "format": "RGB888"},
                lores={"size": (640, 640), "format": "RGB888"}
            )
            picam2.configure(config)
            
            # Start camera
            picam2.start()
            print("✓ Camera started")
            print(f"✓ Resolution: 1920x1080")
            if self.model_path:
                print(f"✓ Hailo model: {self.model_path.name}")
            print("\nCapturing frames... (Ctrl+C to stop)")
            print(f"Saving preview every {self.save_interval} frames\n")
            
            self.running = True
            start_time = time.time()
            last_save_time = start_time
            
            while self.running:
                try:
                    # Capture frame
                    frame = picam2.capture_array("main")
                    self.frame_count += 1
                    
                    # Process frame
                    img = self.process_frame(frame)
                    
                    # Calculate FPS
                    elapsed = time.time() - start_time
                    fps = self.frame_count / elapsed if elapsed > 0 else 0
                    
                    # Add FPS to image
                    img = self.draw_text_pil(img, f"FPS: {fps:.1f}", (10, 40), (255, 255, 0))
                    
                    # Save periodically or on specific frames
                    if self.frame_count % self.save_interval == 0:
                        filename = f"preview_frame_{self.frame_count:06d}.jpg"
                        img.save(filename, quality=85)
                        print(f"Saved: {filename} (FPS: {fps:.1f})")
                    
                    # Also save latest frame
                    if time.time() - last_save_time > 2:  # Every 2 seconds
                        img.save("latest_preview.jpg", quality=85)
                        last_save_time = time.time()
                    
                    # Small delay to control frame rate
                    time.sleep(0.03)  # ~30 FPS max
                    
                except KeyboardInterrupt:
                    break
                except Exception as e:
                    print(f"Frame processing error: {e}")
                    continue
            
            # Final statistics
            total_time = time.time() - start_time
            avg_fps = self.frame_count / total_time if total_time > 0 else 0
            
            print("\n" + "═" * 60)
            print("Preview Statistics:")
            print(f"  Total frames: {self.frame_count}")
            print(f"  Total time: {total_time:.1f} seconds")
            print(f"  Average FPS: {avg_fps:.1f}")
            print(f"  Saved frames: {self.frame_count // self.save_interval}")
            print("═" * 60)
            
        except Exception as e:
            print(f"Error: {e}")
            
        finally:
            if 'picam2' in locals():
                picam2.stop()
                picam2.close()
            print("\n✓ Preview stopped")

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Hailo Camera Preview without OpenCV")
    parser.add_argument("--model", type=str, 
                       help="Path to HEF model (optional)")
    parser.add_argument("--save-interval", type=int, default=30,
                       help="Save frame every N frames (default: 30)")
    parser.add_argument("--duration", type=int, default=0,
                       help="Run for N seconds (0=infinite)")
    
    args = parser.parse_args()
    
    # Check model if provided
    if args.model:
        model_path = Path(args.model)
        if not model_path.exists():
            print(f"Warning: Model not found: {model_path}")
            model_path = None
    else:
        # Try to use default model
        default_model = Path("/home/crtr/Projects/open-hailo/models/yolov8s.hef")
        if default_model.exists():
            model_path = default_model
            print(f"Using default model: {model_path.name}")
        else:
            model_path = None
            print("Running without Hailo model (camera only)")
    
    # Run preview
    preview = CameraPreviewNoCv(
        model_path=model_path,
        save_interval=args.save_interval
    )
    
    if args.duration > 0:
        # Run for specific duration
        timer = Thread(target=lambda: (time.sleep(args.duration), setattr(preview, 'running', False)))
        timer.start()
    
    preview.run()

if __name__ == "__main__":
    main()
