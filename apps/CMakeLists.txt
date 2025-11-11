cmake_minimum_required(VERSION 3.10)
project(hailo_device_test)

# C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Find HailoRT package
find_package(HailoRT 4.20.0 REQUIRED)

# Create the executable
add_executable(device_test device_test.cpp)

# Link HailoRT
target_link_libraries(device_test PRIVATE HailoRT::libhailort)

# Add compile options
target_compile_options(device_test PRIVATE -Wall -Wextra -O2)
