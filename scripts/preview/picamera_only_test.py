#!/usr/bin/env python3
"""
Pure Picamera2 test - No OpenCV required
Uses matplotlib for display if available, otherwise saves images
"""

import time
import numpy as np
from picamera2 import Picamera2
from pathlib import Path

def main():
    print("═" * 60)
    print("     Pure Picamera2 Test (No OpenCV Required)")
    print("═" * 60)
    
    # Try to import matplotlib for display
    try:
        import matplotlib.pyplot as plt
        from matplotlib import animation
        DISPLAY_AVAILABLE = True
        print("✓ Matplotlib found - will show live preview")
    except ImportError:
        DISPLAY_AVAILABLE = False
        print("ℹ Matplotlib not found - will save test images only")
    
    try:
        # Initialize camera
        print("\nInitializing camera...")
        picam2 = Picamera2()
        
        # Get camera info
        print(f"Camera Model: {picam2.camera_properties.get('Model', 'Unknown')}")
        print(f"Sensor Size: {picam2.camera_properties.get('PixelArraySize', 'Unknown')}")
        
        # Configure for capture
        config = picam2.create_still_configuration(
            main={"size": (1920, 1080), "format": "RGB888"}
        )
        picam2.configure(config)
        
        # Start camera
        picam2.start()
        print("✓ Camera started successfully!\n")
        
        if DISPLAY_AVAILABLE:
            # Live preview with matplotlib
            print("Starting live preview...")
            print("Close the window to stop\n")
            
            fig, ax = plt.subplots(figsize=(12, 7))
            plt.title("Picamera2 Live Preview - Close window to stop")
            
            # Initial capture
            frame = picam2.capture_array("main")
            im = ax.imshow(frame)
            ax.axis('off')
            
            # Animation update function
            def update(frame_num):
                frame = picam2.capture_array("main")
                im.set_array(frame)
                # Update title with frame counter
                plt.title(f"Picamera2 Live Preview - Frame {frame_num}")
                return [im]
            
            # Create animation
            ani = animation.FuncAnimation(fig, update, interval=50, blit=True, cache_frame_data=False)
            
            try:
                plt.show()
            except KeyboardInterrupt:
                print("\nStopped by user")
            
        else:
            # Just capture test images
            print("Capturing test images...")
            
            for i in range(5):
                print(f"Capturing image {i+1}/5...")
                
                # Capture frame
                frame = picam2.capture_array("main")
                
                # Save as numpy array (can be loaded later)
                filename = f"test_capture_{i+1}.npy"
                np.save(filename, frame)
                print(f"  ✓ Saved: {filename} (shape: {frame.shape})")
                
                # Also try to save as image if PIL is available
                try:
                    from PIL import Image
                    img = Image.fromarray(frame)
                    img_filename = f"test_capture_{i+1}.jpg"
                    img.save(img_filename)
                    print(f"  ✓ Also saved as: {img_filename}")
                except ImportError:
                    pass
                
                time.sleep(1)
            
            print("\n✓ Test captures completed!")
            print("Files saved in current directory")
        
        # Capture one final high-quality image
        print("\nCapturing final high-quality image...")
        request = picam2.capture_request()
        request.save("main", "final_capture.jpg")
        request.release()
        print("✓ Saved: final_capture.jpg")
        
        # Print camera stats
        metadata = picam2.capture_metadata()
        print("\nCamera Metadata:")
        print(f"  Exposure Time: {metadata.get('ExposureTime', 'N/A')} µs")
        print(f"  Analogue Gain: {metadata.get('AnalogueGain', 'N/A')}")
        print(f"  Lens Position: {metadata.get('LensPosition', 'N/A')}")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("\nTroubleshooting:")
        print("1. Check camera connection")
        print("2. Run: v4l2-ctl --list-devices")
        print("3. Try: ~/local/bin/rpicam-hello -t 5000")
        
    finally:
        # Cleanup
        if 'picam2' in locals():
            picam2.stop()
            picam2.close()
        print("\n✓ Camera test completed")

if __name__ == "__main__":
    main()
