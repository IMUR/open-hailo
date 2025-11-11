# Hailo Model Pipeline Guide

## Overview

The Hailo AI accelerator requires models in HEF (Hailo Executable Format). This guide explains the open-source approach to model deployment.

## Model Conversion Workflow

### 1. Source Model Formats

Hailo supports conversion from:

- ONNX (recommended for open-source workflow)
- TensorFlow/TFLite
- PyTorch (via ONNX export)

### 2. Conversion Process

The conversion requires Hailo's Model Zoo or Dataflow Compiler (DFC). While the DFC is proprietary, the workflow is:

```
ONNX Model → Hailo Parser → Optimization → Quantization → HEF File
```

### 3. Open-Source Alternatives

For a fully open-source pipeline:

1. **Use Pre-converted Models**: Some community members share HEF files
2. **ONNX Direct Inference**: Use ONNX Runtime with CPU/GPU fallback
3. **Model Optimization**: Use open tools like:
   - ONNX Simplifier
   - TensorRT (for NVIDIA comparison)
   - OpenVINO (for Intel comparison)

### 4. Basic Inference Example

```cpp
// Pseudocode for HEF-based inference
auto hef = Hef::create("model.hef");
auto network_group = device.configure(hef);
auto input_vstream = VStreamsBuilder::create_input_vstreams(network_group);
auto output_vstream = VStreamsBuilder::create_output_vstreams(network_group);

// Run inference
input_vstream.write(input_data);
output_vstream.read(output_data);
```

## Performance Considerations

1. **Batch Processing**: Hailo-8 excels at batch inference
2. **Pipeline Optimization**: Use multiple streams for throughput
3. **Memory Management**: Pre-allocate DMA buffers for efficiency

## Community Resources

- Hailo Community Forum: <https://community.hailo.ai/>
- Example Models: Check community repositories
- Performance Benchmarks: Document your results

## Next Steps

1. Obtain or convert a simple model (e.g., MobileNet)
2. Test inference performance
3. Compare with CPU/GPU baselines
4. Share benchmarks with community
