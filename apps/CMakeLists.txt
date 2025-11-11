cmake_minimum_required(VERSION 3.10)
project(hailo_examples)

# C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Find HailoRT package
find_package(HailoRT 4.20.0 REQUIRED)

# Device test application (comprehensive validation)
add_executable(device_test device_test.cpp)
target_link_libraries(device_test PRIVATE HailoRT::libhailort)
target_compile_options(device_test PRIVATE -Wall -Wextra -O2)

# Simple example (perfect for new contributors)
add_executable(simple_example simple_example.cpp)
target_link_libraries(simple_example PRIVATE HailoRT::libhailort)
target_compile_options(simple_example PRIVATE -Wall -Wextra -O2)
