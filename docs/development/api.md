# API Reference

HailoRT API documentation, model pipeline details, and preview options.

---

## 🎯 HailoRT C++ API

### Complete Inference Pipeline

```
VDevice::create() → Hef::create() → configure() → VStreams → inference
```

### Step-by-Step Usage

#### 1. Create Virtual Device

```cpp
#include "hailo/hailort.hpp"
using namespace hailort;

auto vdevice = VDevice::create();
if (!vdevice) {
    std::cerr << "Failed: " << vdevice.status() << std::endl;
}
```

#### 2. Load HEF Model

```cpp
auto hef = Hef::create("model.hef");
if (!hef) {
    std::cerr << "Failed: " << hef.status() << std::endl;
}
```

#### 3. Configure Device

```cpp
auto configure_params = hef->create_configure_params(HAILO_STREAM_INTERFACE_PCIE);
auto network_groups = vdevice.value()->configure(hef.value(), configure_params.value());
auto& network_group = network_groups->at(0);
```

#### 4. Create Input/Output Streams

```cpp
// Get stream parameters
auto input_params = hef->make_input_vstream_params(network_group, ...);
auto output_params = hef->make_output_vstream_params(network_group, ...);

// Create streams
auto input_streams = VStreamsBuilder::create_input_vstreams(network_group, input_params.value());
auto output_streams = VStreamsBuilder::create_output_vstreams(network_group, output_params.value());
```

#### 5. Run Inference

```cpp
// Prepare data
std::vector<uint8_t> input_data(input_size);
std::vector<uint8_t> output_data(output_size);

// Write input
auto& input_stream = input_streams->at(0);
input_stream.write(MemoryView(input_data.data(), input_data.size()));

// Read output
auto& output_stream = output_streams->at(0);
output_stream.read(MemoryView(output_data.data(), output_data.size()));
```

### Memory Management

```cpp
// DMA buffer (best performance)
auto buffer = Buffer::create_shared(size, BufferStorageParams::create_dma());

// Regular heap buffer  
auto buffer = Buffer::create_shared(size);

// Zero-copy view
MemoryView view(data_ptr, data_size);
```

### Device Information

```cpp
auto devices = vdevice.value()->get_physical_devices();
auto& device = devices->at(0).get();

// Identity
auto identity = device.identify();
std::cout << "Device: " << identity->board_name << std::endl;
std::cout << "Firmware: " << (int)identity->fw_version.major << "."
          << (int)identity->fw_version.minor << "."
          << (int)identity->fw_version.revision << std::endl;

// Temperature
auto temp = device.get_chip_temperature();
std::cout << "Temp: " << temp->ts0_temperature << "°C" << std::endl;

// Architecture
auto arch = device.get_architecture();
```

---

## 📦 Model Pipeline Architecture

### YOLOv8 Pipeline Flow

```
Camera → Capture → Resize → Normalize → Hailo Inference → Post-Process → Display
  ↓          ↓         ↓         ↓             ↓               ↓            ↓
OV5647   V4L2/     640x640   0.0-1.0    Hailo-8 NPU    Parse boxes   X11/EGL
        rpicam               RGB float                  + labels      window
```

### Data Flow Details

**Input:**
- Resolution: 640x640 (YOLOv8 default)
- Format: RGB float32 or uint8
- Normalization: 0.0-1.0 range
- Layout: NHWC (batch, height, width, channels)

**Inference:**
- Device: Hailo-8 NPU
- Throughput: 60-100 FPS depending on model
- Latency: 10-25ms per frame

**Output:**
- Bounding boxes: [x, y, w, h]
- Confidence scores: 0.0-1.0
- Class IDs: 0-79 (COCO classes)
- Format: Varies by model (typically [N, 85] or [N, 84])

### Pre-Processing

```cpp
// Resize image to model input size
cv::Mat resized;
cv::resize(input, resized, cv::Size(640, 640));

// Convert to RGB if needed
cv::cvtColor(resized, resized, cv::COLOR_BGR2RGB);

// Normalize to 0.0-1.0
resized.convertTo(normalized, CV_32F, 1.0/255.0);
```

### Post-Processing (YOLOv8)

```cpp
// Parse detections (pseudo-code)
for (auto& detection : output_data) {
    float confidence = detection[4];
    if (confidence > threshold) {
        int class_id = argmax(detection + 5);  // Classes start at index 5
        float x = detection[0];
        float y = detection[1];
        float w = detection[2];
        float h = detection[3];
        
        // Draw bounding box and label
    }
}
```

---

## 🎥 Preview & Display Options

### Option 1: rpicam-hello with Hailo (Best)

**Features:**
- Hardware-accelerated display (RPi GPU)
- Real-time bounding boxes
- Class labels and confidence
- 30-60 FPS with overlays

**Usage:**
```bash
rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json
```

**Requirements:** rpicam-apps built with Hailo support

---

### Option 2: GStreamer Pipeline

**Features:**
- Professional video pipeline
- Network streaming support
- Multiple output formats
- Advanced processing

**Usage:**
```bash
gst-launch-1.0 \
    v4l2src device=/dev/video0 ! \
    video/x-raw,width=640,height=640 ! \
    hailonet hef-path=models/yolov8s.hef ! \
    hailofilter ! \
    hailooverlay ! \
    xvimagesink
```

**Requirements:** GStreamer + Hailo plugins (from TAPPAS)

---

### Option 3: Custom Python/OpenCV

**Features:**
- Full customization
- Easy to modify
- Integration with Python ecosystem

**Usage:**
```python
import cv2
from hailo_platform import VDevice, HEF, InferVStreams

# Open camera
cap = cv2.VideoCapture(0)

# Load model
vdevice = VDevice()
hef = HEF("models/yolov8s.hef")

# Run inference loop
while True:
    ret, frame = cap.read()
    # ... preprocess, inference, draw boxes ...
    cv2.imshow("Hailo Preview", frame)
```

**Requirements:** OpenCV, Hailo Python bindings (optional)

---

### Comparison

| Method | Performance | Setup | Customization |
|--------|-------------|-------|---------------|
| rpicam-hello | ⭐⭐⭐⭐⭐ | Easy | Limited |
| GStreamer | ⭐⭐⭐⭐⭐ | Medium | High |
| Custom Python | ⭐⭐⭐⭐ | Easy | Very High |

---

## 🔌 Camera Integration

### V4L2 (Low-level)

```cpp
int fd = open("/dev/video0", O_RDWR);

struct v4l2_format fmt = {};
fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
fmt.fmt.pix.width = 640;
fmt.fmt.pix.height = 480;
fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;

ioctl(fd, VIDIOC_S_FMT, &fmt);
```

### rpicam-apps (High-level - Recommended)

```bash
# Preview with post-processing
rpicam-hello -t 0 --post-process-file config.json

# Capture with annotations
rpicam-still -o output.jpg --post-process-file config.json

# Video recording
rpicam-vid -t 10000 -o video.h264 --post-process-file config.json
```

---

## 🧩 Post-Processing Stages

Stages available after building with Hailo support:

### Hailo Stages (from TAPPAS):
- `hailo_yolo_inference` - YOLOv5/v6/v8 object detection
- `hailo_yolov8_pose` - Pose estimation
- `hailo_classifier` - Image classification
- `hailo_scrfd` - Face detection
- `hailo_yolov5_segmentation` - Instance segmentation

### OpenCV Stages:
- `object_detect_draw_cv` - Draw bounding boxes
- `face_detect_cv` - Face detection (OpenCV)
- `sobel_cv` - Edge detection
- `annotate_cv` - Text annotation

### Core Stages:
- `hdr` - HDR processing
- `motion_detect` - Motion detection
- `negate` - Image inversion

---

## 📊 Performance Tuning

### Optimize for Speed:
```json
{
    "rpicam-apps": { "lores": { "width": 416, "height": 416 } },
    "hailo_yolo_inference": { "threshold": 0.6, "max_detections": 10 }
}
```

### Optimize for Accuracy:
```json
{
    "rpicam-apps": { "lores": { "width": 1280, "height": 1280 } },
    "hailo_yolo_inference": { "threshold": 0.4, "max_detections": 50 }
}
```

### Balance (Recommended):
```json
{
    "rpicam-apps": { "lores": { "width": 640, "height": 640 } },
    "hailo_yolo_inference": { "threshold": 0.5, "max_detections": 20 }
}
```

---

## 🛠️ Development Workflow

1. **Modify** C++ code in `apps/`
2. **Build** with `./scripts/build/build.sh`
3. **Test** executable in `apps/build/`
4. **Integrate** with rpicam-apps as post-processing stage

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed developer guide.
