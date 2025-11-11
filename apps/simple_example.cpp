/**
 * Simple Hailo Device Example
 * 
 * This is a minimal example showing how to:
 * 1. Connect to a Hailo device
 * 2. Get basic device information
 * 3. Allocate memory buffers
 * 
 * Perfect starting point for new contributors!
 */

#include "hailo/hailort.hpp"
#include <iostream>

using namespace hailort;

int main() {
    std::cout << "Simple Hailo Device Example" << std::endl;
    std::cout << "===========================" << std::endl;
    
    // Step 1: Create a virtual device (container for physical devices)
    std::cout << "\n1. Creating virtual device..." << std::endl;
    auto vdevice = VDevice::create();
    if (!vdevice) {
        std::cerr << "Failed to create VDevice: " << vdevice.status() << std::endl;
        return -1;
    }
    std::cout << "✓ Virtual device created successfully!" << std::endl;
    
    // Step 2: Get physical devices
    std::cout << "\n2. Getting physical devices..." << std::endl;
    auto physical_devices = vdevice.value()->get_physical_devices();
    if (!physical_devices) {
        std::cerr << "Failed to get physical devices: " << physical_devices.status() << std::endl;
        return -1;
    }
    
    if (physical_devices->empty()) {
        std::cout << "No Hailo devices found. Make sure:" << std::endl;
        std::cout << "- Hailo device is connected" << std::endl;
        std::cout << "- Driver is loaded (sudo modprobe hailo_pci)" << std::endl;
        std::cout << "- Device permissions are correct" << std::endl;
        return -1;
    }
    
    std::cout << "✓ Found " << physical_devices->size() << " device(s)" << std::endl;
    
    // Step 3: Work with the first device
    std::cout << "\n3. Getting device information..." << std::endl;
    auto& device = physical_devices->at(0).get();
    
    // Get device ID
    auto device_id = device.get_dev_id();
    std::cout << "Device ID: " << device_id << std::endl;
    
    // Get architecture
    auto arch = device.get_architecture();
    if (arch.has_value()) {
        std::cout << "Architecture: " << arch.value() << std::endl;
    }
    
    // Get device identity (firmware version, etc.)
    auto identity = device.identify();
    if (identity.has_value()) {
        std::cout << "Board Name: " << identity->board_name << std::endl;
        std::cout << "Firmware Version: " 
                  << (int)identity->fw_version.major << "."
                  << (int)identity->fw_version.minor << "."
                  << (int)identity->fw_version.revision << std::endl;
    }
    
    // Step 4: Allocate a buffer (demonstrates memory management)
    std::cout << "\n4. Testing memory allocation..." << std::endl;
    size_t buffer_size = 1024; // 1KB buffer
    auto buffer = Buffer::create_shared(buffer_size, BufferStorageParams::create_dma());
    
    if (buffer.has_value()) {
        std::cout << "✓ Successfully allocated " << buffer.value()->size() << " byte DMA buffer" << std::endl;
        
        // You can access buffer data with:
        // buffer.value()->data() - returns void* to buffer data
        // buffer.value()->size() - returns buffer size in bytes
    } else {
        std::cout << "⚠ DMA buffer allocation failed (this is often normal)" << std::endl;
        std::cout << "  Trying regular buffer..." << std::endl;
        
        auto regular_buffer = Buffer::create_shared(buffer_size);  // Default is heap allocation
        if (regular_buffer.has_value()) {
            std::cout << "✓ Successfully allocated " << regular_buffer.value()->size() << " byte regular buffer" << std::endl;
        }
    }
    
    std::cout << "\n🎉 Example completed successfully!" << std::endl;
    std::cout << "\nNext steps:" << std::endl;
    std::cout << "- Check out device_test.cpp for more advanced examples" << std::endl;
    std::cout << "- Read docs/DEVELOPER_GUIDE.md for API details" << std::endl;
    std::cout << "- Try loading a HEF model for inference" << std::endl;
    
    return 0;
}
