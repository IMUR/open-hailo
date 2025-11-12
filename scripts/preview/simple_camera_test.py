#!/usr/bin/env python3
"""
Simple Camera Test - Verify camera is working
No Hailo inference, just camera preview
"""

import cv2
import time
import numpy as np
from picamera2 import Picamera2

def main():
    print("═" * 60)
    print("     Simple Camera Test (No Hailo)")  
    print("═" * 60)
    
    try:
        # Initialize camera
        picam2 = Picamera2()
        
        # Configure for preview
        config = picam2.create_preview_configuration(
            main={"size": (1920, 1080), "format": "RGB888"}
        )
        picam2.configure(config)
        
        # Start camera
        picam2.start()
        print("✓ Camera started successfully!")
        print("\nPress 'q' to quit, 's' to save screenshot")
        print("Press 'i' for camera info")
        
        # Create window
        cv2.namedWindow("Camera Test", cv2.WINDOW_NORMAL)
        cv2.resizeWindow("Camera Test", 1280, 720)
        
        frame_count = 0
        start_time = time.time()
        
        while True:
            # Capture frame
            frame = picam2.capture_array("main")
            
            # Convert RGB to BGR for OpenCV
            frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
            
            # Calculate FPS
            frame_count += 1
            elapsed = time.time() - start_time
            fps = frame_count / elapsed if elapsed > 0 else 0
            
            # Add text overlay
            cv2.putText(frame_bgr, f"FPS: {fps:.1f}", (10, 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.putText(frame_bgr, f"Resolution: {frame.shape[1]}x{frame.shape[0]}", (10, 70),
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.putText(frame_bgr, "Camera: OV5647", (10, 110),
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            
            # Show frame
            cv2.imshow("Camera Test", frame_bgr)
            
            # Handle key press
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('s'):
                filename = f"camera_test_{int(time.time())}.jpg"
                cv2.imwrite(filename, frame_bgr)
                print(f"✓ Saved: {filename}")
            elif key == ord('i'):
                print("\n" + "─" * 40)
                print("Camera Information:")
                print(f"  Model: {picam2.camera_properties.get('Model', 'Unknown')}")
                print(f"  Sensor Resolution: {picam2.camera_properties.get('PixelArraySize', 'Unknown')}")
                print(f"  Current FPS: {fps:.1f}")
                print(f"  Frame Shape: {frame.shape}")
                print("─" * 40 + "\n")
        
    except Exception as e:
        print(f"Error: {e}")
        print("\nTroubleshooting:")
        print("1. Make sure camera is connected")
        print("2. Run: v4l2-ctl --list-devices")
        print("3. Check: libcamera-hello")
        
    finally:
        # Cleanup
        picam2.stop()
        picam2.close()
        cv2.destroyAllWindows()
        print("\n✓ Camera test completed")

if __name__ == "__main__":
    main()
