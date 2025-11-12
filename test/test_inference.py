#!/usr/bin/env python3
"""
Test YOLOv5 inference on Hailo-8 with captured image
"""

import numpy as np
from PIL import Image
from hailo_platform import (
    HEF,
    VDevice,
    FormatType,
    HailoStreamInterface,
    ConfigureParams,
    InferVStreams,
    InputVStreamParams,
    OutputVStreamParams
)

def prepare_image(image_path, target_size=(640, 640)):
    """Prepare image for YOLOv5 inference"""
    img = Image.open(image_path)
    print(f"Original image size: {img.size}")
    
    # Resize to target size (YOLOv5 typically uses 640x640)
    img_resized = img.resize(target_size, Image.Resampling.LANCZOS)
    
    # Convert to RGB if needed
    if img_resized.mode != 'RGB':
        img_resized = img_resized.convert('RGB')
    
    # Convert to numpy array and normalize to [0, 1]
    img_array = np.array(img_resized, dtype=np.float32) / 255.0
    
    # YOLOv5 expects NHWC format (batch, height, width, channels)
    img_array = np.expand_dims(img_array, axis=0)
    
    return img_array

def main():
    print("Hailo-8 YOLOv5 Inference Test")
    print("=" * 40)
    
    hef_path = "yolov5m.hef"
    image_path = "test_capture.jpg"
    
    try:
        # Step 1: Create VDevice
        print("\n1. Initializing Hailo device...")
        with VDevice() as target:
            print("✓ Device initialized")
            
            # Step 2: Load HEF
            print("\n2. Loading YOLOv5 model...")
            hef = HEF(hef_path)
            print(f"✓ Model loaded: {hef_path}")
            
            # Step 3: Configure network
            print("\n3. Configuring network...")
            configure_params = ConfigureParams.create_from_hef(hef, HailoStreamInterface.PCIe)
            network_groups = target.configure(hef, configure_params)
            print(f"✓ Configured {len(network_groups)} network group(s)")
            
            if not network_groups:
                print("✗ No network groups found")
                return
            
            network_group = network_groups[0]
            network_name = network_group.get_network_infos()[0].name if network_group.get_network_infos() else "yolov5"
            
            # Step 4: Get input/output info
            print("\n4. Getting model information...")
            input_vstreams_params = InputVStreamParams.make(network_group, format_type=FormatType.FLOAT32)
            output_vstreams_params = OutputVStreamParams.make(network_group, format_type=FormatType.FLOAT32)
            
            # Display stream info
            print("\nInput streams:")
            for name, params in input_vstreams_params.items():
                print(f"  - {name}: shape={params.shape}")
                input_shape = params.shape
            
            print("\nOutput streams:")
            for name, params in output_vstreams_params.items():
                print(f"  - {name}: shape={params.shape}")
            
            # Step 5: Prepare input data
            print("\n5. Preparing input image...")
            
            # Get expected input dimensions from model
            # YOLOv5 typically expects (1, 640, 640, 3) or (1, 3, 640, 640)
            if len(input_vstreams_params) > 0:
                first_input = list(input_vstreams_params.values())[0]
                expected_shape = first_input.shape
                print(f"Model expects input shape: {expected_shape}")
                
                # Prepare image based on expected shape
                if len(expected_shape) == 4:
                    if expected_shape[3] == 3:  # NHWC format
                        target_size = (expected_shape[2], expected_shape[1])
                    else:  # NCHW format
                        target_size = (expected_shape[3], expected_shape[2])
                else:
                    target_size = (640, 640)  # Default
                
                input_data = prepare_image(image_path, target_size)
                
                # Adjust format if needed (NCHW vs NHWC)
                if len(expected_shape) == 4 and expected_shape[1] == 3:
                    # Convert from NHWC to NCHW if needed
                    input_data = np.transpose(input_data, (0, 3, 1, 2))
                
                print(f"✓ Input prepared: shape={input_data.shape}")
            
            # Step 6: Create inference pipeline
            print("\n6. Creating inference pipeline...")
            with InferVStreams(network_group, input_vstreams_params, output_vstreams_params) as infer_pipeline:
                print("✓ Pipeline created")
                
                # Step 7: Run inference
                print("\n7. Running inference...")
                
                # Prepare input dict
                input_dict = {list(input_vstreams_params.keys())[0]: input_data}
                
                # Run inference
                with network_group.activate():
                    results = infer_pipeline.infer(input_dict)
                
                print("✓ Inference completed!")
                
                # Step 8: Process results
                print("\n8. Results:")
                for output_name, output_data in results.items():
                    print(f"\nOutput '{output_name}':")
                    print(f"  Shape: {output_data.shape}")
                    print(f"  Min value: {np.min(output_data):.4f}")
                    print(f"  Max value: {np.max(output_data):.4f}")
                    print(f"  Mean value: {np.mean(output_data):.4f}")
                    
                    # For YOLOv5, typically the output contains bounding boxes
                    # Format is usually [batch, num_predictions, 85] where 85 = 4 (bbox) + 1 (confidence) + 80 (classes)
                    if len(output_data.shape) == 3 and output_data.shape[-1] >= 85:
                        # Extract detections with confidence > threshold
                        threshold = 0.5
                        detections = output_data[0]  # First batch
                        confidences = detections[:, 4]
                        high_conf_indices = np.where(confidences > threshold)[0]
                        
                        if len(high_conf_indices) > 0:
                            print(f"\n  Found {len(high_conf_indices)} detections with confidence > {threshold}")
                            for idx in high_conf_indices[:5]:  # Show first 5
                                conf = detections[idx, 4]
                                class_scores = detections[idx, 5:]
                                class_id = np.argmax(class_scores)
                                class_conf = class_scores[class_id]
                                bbox = detections[idx, :4]
                                print(f"    Detection: conf={conf:.2f}, class={class_id}, class_conf={class_conf:.2f}")
                        else:
                            print(f"  No detections with confidence > {threshold}")
                
                print("\n🎉 Inference test completed successfully!")
                print("\nYour jerry-rigged Hailo-8 + RPi5 + OV5647 camera stack is fully operational!")
                
    except ImportError as e:
        print(f"✗ Python API not available: {e}")
        print("\nTo install Hailo Python API:")
        print("  pip install hailo-platform")
        print("\nOr check if it's available in:")
        print("  /usr/local/lib/python*/dist-packages/")
        
    except FileNotFoundError as e:
        print(f"✗ File not found: {e}")
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
