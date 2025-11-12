#!/usr/bin/env python3
"""
Live Preview with Hailo Inference Overlay
Adapts based on available libraries and display options
"""

import subprocess
import sys
import time
import json
from pathlib import Path

# Check available libraries
HAS_CV2 = False
HAS_PIL = False
HAS_NUMPY = False

try:
    import cv2
    HAS_CV2 = True
    print("✓ OpenCV available")
except ImportError:
    print("✗ OpenCV not available (install: sudo apt install python3-opencv)")

try:
    from PIL import Image, ImageDraw, ImageFont
    HAS_PIL = True
    print("✓ PIL available")
except ImportError:
    print("✗ PIL not available (install: sudo apt install python3-pil)")

try:
    import numpy as np
    HAS_NUMPY = True
    print("✓ NumPy available")
except ImportError:
    print("✗ NumPy not available (install: sudo apt install python3-numpy)")


class HailoPreview:
    """Preview handler that adapts to available display methods"""
    
    def __init__(self, output_dir="./preview_frames"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.frame_count = 0
        
    def mode_1_rpicam_official(self):
        """Try official RPi + Hailo integration"""
        print("\n" + "="*60)
        print("MODE 1: Official Raspberry Pi + Hailo Integration")
        print("="*60)
        
        # Check for post-processing files
        post_process_dir = Path("/usr/share/rpi-camera-assets")
        if not post_process_dir.exists():
            print("✗ Hailo post-processing assets not found")
            print("\nInstall with:")
            print("  sudo apt install rpicam-apps-hailo-postprocess")
            return False
        
        # Find Hailo config files
        configs = list(post_process_dir.glob("hailo*.json"))
        if not configs:
            print("✗ No Hailo config files found")
            return False
        
        print(f"✓ Found {len(configs)} Hailo config(s):")
        for config in configs:
            print(f"  - {config.name}")
        
        # Try to run with the first config
        config = configs[0]
        print(f"\nStarting preview with {config.name}...")
        print("Press Ctrl+C to stop")
        
        try:
            cmd = ["rpicam-hello", "-t", "0", "--post-process-file", str(config)]
            subprocess.run(cmd)
            return True
        except KeyboardInterrupt:
            print("\nPreview stopped")
            return True
        except Exception as e:
            print(f"✗ Error: {e}")
            return False
    
    def mode_2_opencv_preview(self):
        """OpenCV-based preview with custom overlay"""
        print("\n" + "="*60)
        print("MODE 2: Custom OpenCV Preview")
        print("="*60)
        
        if not HAS_CV2:
            print("✗ OpenCV not available")
            return False
        
        print("✓ OpenCV available")
        print("\nThis mode captures frames and displays them with overlays")
        print("Note: Actual inference integration requires Hailo Python bindings")
        print("\nStarting preview... (Press 'q' to quit)")
        
        try:
            # Try to open camera with OpenCV
            cap = cv2.VideoCapture(0)
            if not cap.isOpened():
                print("✗ Could not open camera with OpenCV")
                return False
            
            print("✓ Camera opened")
            
            frame_count = 0
            fps_start = time.time()
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    print("✗ Failed to capture frame")
                    break
                
                # Calculate FPS
                frame_count += 1
                if frame_count % 30 == 0:
                    fps = 30 / (time.time() - fps_start)
                    fps_start = time.time()
                else:
                    fps = 0
                
                # Add info overlay
                height, width = frame.shape[:2]
                
                # Draw info box
                cv2.rectangle(frame, (10, 10), (300, 100), (0, 0, 0), -1)
                cv2.rectangle(frame, (10, 10), (300, 100), (0, 255, 0), 2)
                
                cv2.putText(frame, "Hailo-8 Camera Preview", (20, 35),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
                cv2.putText(frame, f"Resolution: {width}x{height}", (20, 60),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
                if fps > 0:
                    cv2.putText(frame, f"FPS: {fps:.1f}", (20, 85),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
                
                # Draw mock detection box (for demo)
                cv2.rectangle(frame, (width//4, height//4), 
                             (3*width//4, 3*height//4), (0, 255, 255), 2)
                cv2.putText(frame, "Detection Zone", (width//4 + 10, height//4 + 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
                
                # Display
                cv2.imshow("Hailo-8 Live Preview", frame)
                
                # Check for quit
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
            
            cap.release()
            cv2.destroyAllWindows()
            print("✓ Preview stopped")
            return True
            
        except Exception as e:
            print(f"✗ Error: {e}")
            return False
    
    def mode_3_capture_and_save(self):
        """Capture frames and save to disk (for headless operation)"""
        print("\n" + "="*60)
        print("MODE 3: Capture & Save (Headless Mode)")
        print("="*60)
        
        print("This mode captures frames periodically and saves them")
        print(f"Output directory: {self.output_dir}")
        print("\nPress Ctrl+C to stop\n")
        
        try:
            frame_num = 0
            while True:
                timestamp = int(time.time())
                output_file = self.output_dir / f"frame_{timestamp}_{frame_num:04d}.jpg"
                
                print(f"Capturing frame {frame_num}...", end=" ")
                
                # Capture with rpicam-still
                cmd = [
                    "rpicam-still",
                    "-o", str(output_file),
                    "--width", "640",
                    "--height", "640",
                    "--nopreview",
                    "-t", "1"
                ]
                
                result = subprocess.run(cmd, capture_output=True, text=True)
                
                if result.returncode == 0:
                    print(f"✓ Saved to {output_file.name}")
                    frame_num += 1
                else:
                    print(f"✗ Failed")
                
                # Wait before next capture
                time.sleep(1)
                
        except KeyboardInterrupt:
            print(f"\n\nCaptured {frame_num} frames to {self.output_dir}")
            print("Preview stopped")
            return True
        except Exception as e:
            print(f"✗ Error: {e}")
            return False
    
    def mode_4_gstreamer(self):
        """GStreamer pipeline preview"""
        print("\n" + "="*60)
        print("MODE 4: GStreamer Pipeline")
        print("="*60)
        
        # Check if gstreamer is available
        try:
            result = subprocess.run(["which", "gst-launch-1.0"], 
                                   capture_output=True, text=True)
            if result.returncode != 0:
                print("✗ GStreamer not installed")
                print("\nInstall with:")
                print("  sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base")
                return False
        except Exception:
            print("✗ GStreamer not available")
            return False
        
        print("✓ GStreamer available")
        print("\nStarting GStreamer preview...")
        print("Press Ctrl+C to stop")
        
        # Simple test pipeline (no Hailo yet)
        pipeline = [
            "gst-launch-1.0",
            "v4l2src", "device=/dev/video0", "!",
            "video/x-raw,width=640,height=480", "!",
            "videoconvert", "!",
            "autovideosink"
        ]
        
        try:
            subprocess.run(pipeline)
            return True
        except KeyboardInterrupt:
            print("\nPreview stopped")
            return True
        except Exception as e:
            print(f"✗ Error: {e}")
            return False


def main():
    print("""
╔═══════════════════════════════════════════════════════════╗
║          Hailo-8 Live Preview Launcher                    ║
╚═══════════════════════════════════════════════════════════╝

Select a preview mode:

  1. Official RPi + Hailo (best performance, requires setup)
  2. OpenCV Preview (custom display, requires opencv)
  3. Capture & Save (headless mode, works now)
  4. GStreamer Pipeline (advanced, requires gstreamer)
  
  0. Auto-detect best available method
  q. Quit
""")
    
    preview = HailoPreview()
    
    while True:
        try:
            choice = input("\nSelect mode (0-4, q): ").strip().lower()
            
            if choice == 'q':
                print("Exiting...")
                break
            
            if choice == '0':
                # Auto-detect best method
                print("\nAuto-detecting best available method...")
                if preview.mode_1_rpicam_official():
                    break
                elif preview.mode_2_opencv_preview():
                    break
                elif preview.mode_4_gstreamer():
                    break
                else:
                    print("\nFalling back to capture & save mode...")
                    preview.mode_3_capture_and_save()
                    break
            
            elif choice == '1':
                preview.mode_1_rpicam_official()
                break
            
            elif choice == '2':
                preview.mode_2_opencv_preview()
                break
            
            elif choice == '3':
                preview.mode_3_capture_and_save()
                break
            
            elif choice == '4':
                preview.mode_4_gstreamer()
                break
            
            else:
                print("Invalid choice. Please select 0-4 or q")
        
        except KeyboardInterrupt:
            print("\n\nExiting...")
            break
        except Exception as e:
            print(f"Error: {e}")
            break


if __name__ == "__main__":
    main()

