# TAPPAS Deployment Guide

Hailo TAPPAS (Application Library) for GStreamer-based AI pipelines.

## Status

✅ **TAPPAS Core Libraries Available**

TAPPAS core C++ post-processing libraries are used by rpicam-apps for Hailo inference. The full TAPPAS GStreamer pipeline system is under development for Trixie.

## What is TAPPAS?

TAPPAS is a standalone product providing:
- **C++ post-processing libraries** - Used by rpicam-apps ✅
- GStreamer plugins for Hailo inference - Not needed for rpicam-apps
- Pre-built AI pipelines - Not needed for rpicam-apps
- Multi-stream processing - Not needed for rpicam-apps

## Important: Two Different Use Cases

### 1. TAPPAS Core for rpicam-apps (Working Now)
- Installs C++ libraries system-wide
- No Python virtual environment needed
- Provides post-processing for rpicam-apps
- See: [rpicam.md](rpicam.md)

### 2. Full TAPPAS GStreamer Pipelines (Under Development)
- Complete standalone product
- Requires Python 3.13 compatibility work
- Alternative to rpicam-apps approach
- Use rpicam-apps instead for now

## Official Resources

- TAPPAS GitHub: https://github.com/hailo-ai/tappas
- Hailo Documentation: https://hailo.ai/developer-zone/documentation/

## More Information

See `../../configs/tappas/README.md` for current status.

