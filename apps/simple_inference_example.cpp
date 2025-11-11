/**
 * Simple Hailo Inference Example
 * 
 * This example demonstrates the complete inference workflow:
 * 1. Load HEF (Hailo Executable Format) model
 * 2. Configure device for the model
 * 3. Create input/output streams
 * 4. Run inference
 * 
 * Usage: ./simple_inference model.hef
 * 
 * Note: This example is ready to run but requires HEF model files.
 * HEF files must be created using Hailo's Dataflow Compiler (DFC).
 */

#include "hailo/hailort.hpp"
#include <iostream>
#include <chrono>
#include <fstream>

using namespace hailort;

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cout << "Usage: " << argv[0] << " <model.hef>" << std::endl;
        std::cout << "\nThis example demonstrates HEF model loading and inference." << std::endl;
        std::cout << "HEF files are created using Hailo's Dataflow Compiler (DFC)." << std::endl;
        std::cout << "\nTo get HEF models:" << std::endl;
        std::cout << "1. Check Hailo Model Zoo: https://github.com/hailo-ai/hailo_model_zoo" << std::endl;
        std::cout << "2. Use Hailo community examples" << std::endl;
        std::cout << "3. Convert ONNX models using Hailo DFC" << std::endl;
        return 1;
    }
    
    std::string hef_file = argv[1];
    
    // Check if HEF file exists
    std::ifstream file(hef_file);
    if (!file.good()) {
        std::cerr << "Error: Cannot open HEF file: " << hef_file << std::endl;
        return 1;
    }
    
    std::cout << "Hailo Inference Example" << std::endl;
    std::cout << "======================" << std::endl;
    std::cout << "HEF Model: " << hef_file << std::endl;
    
    try {
        // Step 1: Create VDevice
        std::cout << "\n1. Creating virtual device..." << std::endl;
        auto vdevice = VDevice::create();
        if (!vdevice) {
            std::cerr << "Failed to create VDevice: " << vdevice.status() << std::endl;
            return 1;
        }
        std::cout << "✓ VDevice created successfully" << std::endl;
        
        // Step 2: Load HEF file
        std::cout << "\n2. Loading HEF model..." << std::endl;
        auto hef = Hef::create(hef_file);
        if (!hef) {
            std::cerr << "Failed to load HEF file: " << hef.status() << std::endl;
            return 1;
        }
        std::cout << "✓ HEF loaded successfully" << std::endl;
        
        // Step 3: Configure the device with the model
        std::cout << "\n3. Configuring device for model..." << std::endl;
        auto configure_params = hef->create_configure_params(HAILO_STREAM_INTERFACE_PCIE);
        if (!configure_params) {
            std::cerr << "Failed to create configure params: " << configure_params.status() << std::endl;
            return 1;
        }
        
        auto network_groups = vdevice.value()->configure(hef.value(), configure_params.value());
        if (!network_groups) {
            std::cerr << "Failed to configure network groups: " << network_groups.status() << std::endl;
            return 1;
        }
        
        if (network_groups->empty()) {
            std::cerr << "No network groups found in HEF" << std::endl;
            return 1;
        }
        
        auto& network_group = network_groups->at(0);
        std::cout << "✓ Device configured with " << network_groups->size() << " network group(s)" << std::endl;
        
        // Step 4: Create input and output streams
        std::cout << "\n4. Creating input/output streams..." << std::endl;
        auto input_vstreams_params = hef->make_input_vstream_params(network_group, HAILO_FORMAT_TYPE_AUTO,
                                                                   HAILO_DEFAULT_VSTREAM_TIMEOUT_MS, HAILO_DEFAULT_VSTREAM_QUEUE_SIZE);
        if (!input_vstreams_params) {
            std::cerr << "Failed to create input vstream params: " << input_vstreams_params.status() << std::endl;
            return 1;
        }
        
        auto output_vstreams_params = hef->make_output_vstream_params(network_group, HAILO_FORMAT_TYPE_AUTO,
                                                                     HAILO_DEFAULT_VSTREAM_TIMEOUT_MS, HAILO_DEFAULT_VSTREAM_QUEUE_SIZE);
        if (!output_vstreams_params) {
            std::cerr << "Failed to create output vstream params: " << output_vstreams_params.status() << std::endl;
            return 1;
        }
        
        auto input_vstreams = VStreamsBuilder::create_input_vstreams(network_group, input_vstreams_params.value());
        if (!input_vstreams) {
            std::cerr << "Failed to create input vstreams: " << input_vstreams.status() << std::endl;
            return 1;
        }
        
        auto output_vstreams = VStreamsBuilder::create_output_vstreams(network_group, output_vstreams_params.value());
        if (!output_vstreams) {
            std::cerr << "Failed to create output vstreams: " << output_vstreams.status() << std::endl;
            return 1;
        }
        
        std::cout << "✓ Created " << input_vstreams->size() << " input stream(s)" << std::endl;
        std::cout << "✓ Created " << output_vstreams->size() << " output stream(s)" << std::endl;
        
        // Step 5: Display model information
        std::cout << "\n5. Model Information:" << std::endl;
        for (size_t i = 0; i < input_vstreams->size(); i++) {
            auto& stream = input_vstreams->at(i);
            auto info = stream.get_info();
            std::cout << "Input " << i << ": " << info.name 
                      << " [" << info.shape.width << "x" << info.shape.height 
                      << "x" << info.shape.features << "]" << std::endl;
        }
        
        for (size_t i = 0; i < output_vstreams->size(); i++) {
            auto& stream = output_vstreams->at(i);
            auto info = stream.get_info();
            std::cout << "Output " << i << ": " << info.name 
                      << " [" << info.shape.width << "x" << info.shape.height 
                      << "x" << info.shape.features << "]" << std::endl;
        }
        
        // Step 6: Prepare dummy input data (in real usage, this would be your image/sensor data)
        std::cout << "\n6. Preparing input data..." << std::endl;
        auto& input_stream = input_vstreams->at(0);
        auto input_info = input_stream.get_info();
        size_t input_size = input_info.shape.width * input_info.shape.height * input_info.shape.features;
        
        std::vector<uint8_t> input_data(input_size, 128); // Fill with dummy data (gray image)
        std::cout << "✓ Prepared " << input_size << " bytes of input data" << std::endl;
        
        // Step 7: Prepare output buffers
        std::cout << "\n7. Preparing output buffers..." << std::endl;
        std::vector<std::vector<uint8_t>> output_buffers;
        for (auto& output_stream : output_vstreams.value()) {
            auto output_info = output_stream.get_info();
            size_t output_size = output_info.shape.width * output_info.shape.height * output_info.shape.features;
            output_buffers.emplace_back(output_size);
            std::cout << "✓ Prepared " << output_size << " bytes for output: " << output_info.name << std::endl;
        }
        
        // Step 8: Run inference
        std::cout << "\n8. Running inference..." << std::endl;
        auto start_time = std::chrono::high_resolution_clock::now();
        
        // Write input data
        auto write_status = input_stream.write(MemoryView(input_data.data(), input_data.size()));
        if (HAILO_SUCCESS != write_status) {
            std::cerr << "Failed to write input data: " << write_status << std::endl;
            return 1;
        }
        
        // Read output data
        for (size_t i = 0; i < output_vstreams->size(); i++) {
            auto& output_stream = output_vstreams->at(i);
            auto read_status = output_stream.read(MemoryView(output_buffers[i].data(), output_buffers[i].size()));
            if (HAILO_SUCCESS != read_status) {
                std::cerr << "Failed to read output data from stream " << i << ": " << read_status << std::endl;
                return 1;
            }
        }
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        
        std::cout << "✓ Inference completed successfully!" << std::endl;
        std::cout << "✓ Inference time: " << duration.count() << " ms" << std::endl;
        
        // Step 9: Display results summary
        std::cout << "\n9. Results Summary:" << std::endl;
        for (size_t i = 0; i < output_buffers.size(); i++) {
            auto& buffer = output_buffers[i];
            auto& stream = output_vstreams->at(i);
            auto info = stream.get_info();
            
            std::cout << "Output " << i << " (" << info.name << "): " << buffer.size() << " bytes" << std::endl;
            
            // Show first few values as example
            std::cout << "  First 8 values: ";
            for (size_t j = 0; j < std::min(size_t(8), buffer.size()); j++) {
                std::cout << static_cast<int>(buffer[j]) << " ";
            }
            std::cout << std::endl;
        }
        
        std::cout << "\n🎉 Inference example completed successfully!" << std::endl;
        std::cout << "\nNext steps:" << std::endl;
        std::cout << "- Replace dummy input with real image data" << std::endl;
        std::cout << "- Parse output based on your model type (classification, detection, etc.)" << std::endl;
        std::cout << "- Integrate with camera capture pipeline" << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "Exception occurred: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}