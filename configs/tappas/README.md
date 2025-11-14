# TAPPAS Configuration

Hailo's TAPPAS (Hailo Application Library) provides GStreamer-based pipelines for production AI deployments.

## Status

🚧 **Under Development**

TAPPAS installation on Trixie (Debian 13) requires additional compatibility work due to Python 3.13 and GCC 14.

## What is TAPPAS?

TAPPAS provides:
- GStreamer plugins for Hailo inference
- Pre-built AI pipelines
- Multi-stream processing
- Production-grade performance

## Installation (When Available)

```bash
cd open-hailo/configs/tappas
./install.sh
```

## Alternative Options

For now, use:
- **rpicam-apps** (`../rpicam/`) - Works now, good performance
- **Python Direct** (`../python-direct/`) - Full control, custom pipelines

## More Information

- TAPPAS docs: https://github.com/hailo-ai/tappas
- See `../../docs/DEVELOPMENT.md` for Trixie compatibility status

