/**
 * Simple Inference Example (Template)
 * 
 * This demonstrates the HailoRT inference API pattern discovered from
 * the official examples. It shows the correct API usage but requires
 * an actual HEF model file to run.
 * 
 * To use:
 * 1. Obtain a HEF model file (e.g., from Hailo RPi5 examples)
 * 2. Place it in the project directory or specify path
 * 3. Compile and run
 */

#include "hailo/hailort.hpp"
#include <iostream>
#include <vector>
#include <iomanip>

using namespace hailort;

// Change this to your HEF file path
#define HEF_FILE "model.hef"  // Replace with actual HEF path

void print_network_info(const std::shared_ptr<ConfiguredNetworkGroup> &network_group) {
    std::cout << "\n=== Network Information ===" << std::endl;
    
    auto input_vstream_infos = network_group->get_input_vstream_infos();
    if (input_vstream_infos.has_value()) {
        std::cout << "Input streams: " << input_vstream_infos->size() << std::endl;
        for (const auto &info : input_vstream_infos.value()) {
            std::cout << "  - " << info.name << ": "
                      << info.shape.width << "x" << info.shape.height
                      << " (size: " << info.shape.features << ")" << std::endl;
        }
    }
    
    auto output_vstream_infos = network_group->get_output_vstream_infos();
    if (output_vstream_infos.has_value()) {
        std::cout << "Output streams: " << output_vstream_infos->size() << std::endl;
        for (const auto &info : output_vstream_infos.value()) {
            std::cout << "  - " << info.name << ": "
                      << info.shape.width << "x" << info.shape.height
                      << " (size: " << info.shape.features << ")" << std::endl;
        }
    }
}

Expected<std::shared_ptr<ConfiguredNetworkGroup>> configure_network_group(VDevice &vdevice, const std::string &hef_path) {
    // Load HEF file
    auto hef = Hef::create(hef_path);
    if (!hef) {
        std::cerr << "Failed to load HEF file: " << hef_path << std::endl;
        return make_unexpected(hef.status());
    }
    
    std::cout << "✓ HEF file loaded successfully" << std::endl;
    
    // Create configuration parameters
    auto configure_params = vdevice.create_configure_params(hef.value());
    if (!configure_params) {
        return make_unexpected(configure_params.status());
    }
    
    // Configure network group
    auto network_groups = vdevice.configure(hef.value(), configure_params.value());
    if (!network_groups) {
        std::cerr << "Failed to configure network group" << std::endl;
        return make_unexpected(network_groups.status());
    }
    
    if (network_groups->size() != 1) {
        std::cerr << "Expected 1 network group, got " << network_groups->size() << std::endl;
        return make_unexpected(HAILO_INTERNAL_FAILURE);
    }
    
    std::cout << "✓ Network group configured" << std::endl;
    
    return std::move(network_groups->at(0));
}

hailo_status run_inference(std::shared_ptr<ConfiguredNetworkGroup> network_group) {
    // Create vstream parameters with auto format conversion
    auto input_vstream_params = network_group->make_input_vstream_params(
        {},                                  // default settings
        HAILO_FORMAT_TYPE_AUTO,             // auto format conversion
        HAILO_DEFAULT_VSTREAM_TIMEOUT_MS,
        HAILO_DEFAULT_VSTREAM_QUEUE_SIZE
    );
    
    auto output_vstream_params = network_group->make_output_vstream_params(
        {},
        HAILO_FORMAT_TYPE_AUTO,
        HAILO_DEFAULT_VSTREAM_TIMEOUT_MS,
        HAILO_DEFAULT_VSTREAM_QUEUE_SIZE
    );
    
    if (!input_vstream_params || !output_vstream_params) {
        std::cerr << "Failed to create vstream params" << std::endl;
        return HAILO_INTERNAL_FAILURE;
    }
    
    // Create input and output vstreams
    auto input_vstreams = VStreamsBuilder::create_input_vstreams(
        *network_group, input_vstream_params.value()
    );
    
    auto output_vstreams = VStreamsBuilder::create_output_vstreams(
        *network_group, output_vstream_params.value()
    );
    
    if (!input_vstreams || !output_vstreams) {
        std::cerr << "Failed to create vstreams" << std::endl;
        return HAILO_INTERNAL_FAILURE;
    }
    
    std::cout << "✓ VStreams created" << std::endl;
    std::cout << "  Input streams: " << input_vstreams->size() << std::endl;
    std::cout << "  Output streams: " << output_vstreams->size() << std::endl;
    
    // Prepare dummy input data (zeros for testing)
    auto &input_vstream = input_vstreams->at(0);
    size_t input_frame_size = input_vstream.get_frame_size();
    std::vector<uint8_t> input_data(input_frame_size, 0);  // Zeros for demo
    
    std::cout << "\n=== Running Inference ===" << std::endl;
    std::cout << "Input frame size: " << input_frame_size << " bytes" << std::endl;
    
    // Write input data
    auto write_status = input_vstream.write(MemoryView(input_data.data(), input_data.size()));
    if (HAILO_SUCCESS != write_status) {
        std::cerr << "Failed to write input data" << std::endl;
        return write_status;
    }
    
    std::cout << "✓ Input data written" << std::endl;
    
    // Flush input (ensures data is sent)
    auto flush_status = input_vstream.flush();
    if (HAILO_SUCCESS != flush_status) {
        std::cerr << "Failed to flush input" << std::endl;
        return flush_status;
    }
    
    // Read output data
    auto &output_vstream = output_vstreams->at(0);
    size_t output_frame_size = output_vstream.get_frame_size();
    std::vector<uint8_t> output_data(output_frame_size);
    
    std::cout << "Output frame size: " << output_frame_size << " bytes" << std::endl;
    
    auto read_status = output_vstream.read(MemoryView(output_data.data(), output_data.size()));
    if (HAILO_SUCCESS != read_status) {
        std::cerr << "Failed to read output data" << std::endl;
        return read_status;
    }
    
    std::cout << "✓ Output data received" << std::endl;
    
    // Display first few bytes of output (for debugging)
    std::cout << "\nFirst 16 bytes of output: ";
    for (size_t i = 0; i < std::min(size_t(16), output_data.size()); i++) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') 
                  << (int)output_data[i] << " ";
    }
    std::cout << std::dec << std::endl;
    
    std::cout << "\n=== Inference Completed Successfully ===" << std::endl;
    
    return HAILO_SUCCESS;
}

int main(int argc, char *argv[]) {
    std::cout << "Simple Inference Example" << std::endl;
    std::cout << "========================" << std::endl;
    
    // Allow HEF path as command-line argument
    std::string hef_path = HEF_FILE;
    if (argc > 1) {
        hef_path = argv[1];
    }
    
    std::cout << "HEF file: " << hef_path << std::endl;
    
    // Create VDevice
    auto vdevice = VDevice::create();
    if (!vdevice) {
        std::cerr << "Failed to create VDevice" << std::endl;
        return vdevice.status();
    }
    
    std::cout << "✓ VDevice created" << std::endl;
    
    // Configure network
    auto network_group = configure_network_group(*vdevice.value(), hef_path);
    if (!network_group) {
        std::cerr << "\nFailed to configure network group." << std::endl;
        std::cerr << "\nTo run this example, you need a HEF model file." << std::endl;
        std::cerr << "See docs/INFERENCE_API.md for how to obtain HEF files." << std::endl;
        return network_group.status();
    }
    
    // Print network information
    print_network_info(network_group.value());
    
    // Run inference
    auto status = run_inference(network_group.value());
    
    if (HAILO_SUCCESS != status) {
        std::cerr << "Inference failed with status: " << status << std::endl;
        return status;
    }
    
    return HAILO_SUCCESS;
}
