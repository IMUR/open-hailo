# TAPPAS Configuration

**Note:** For rpicam-apps Hailo support, TAPPAS core libraries are installed automatically. This directory is for standalone TAPPAS GStreamer pipelines (under development).

## What You Probably Want

If you're here for **rpicam-apps with Hailo inference**, you want:
```bash
cd ../../
./setup.sh
# Choose option 5: rpicam-apps
```

This will install TAPPAS core C++ libraries automatically (no venv, system-wide).

## Full TAPPAS GStreamer Pipelines

Status: 🚧 **Under Development**

Full TAPPAS (standalone GStreamer pipelines) on Trixie requires Python 3.13 compatibility work.

## What is Full TAPPAS?

TAPPAS standalone provides:
- GStreamer plugins for Hailo inference
- Pre-built AI pipelines
- Multi-stream processing
- **Its own Python virtual environment**

**Important:** rpicam-apps doesn't need any of this - just the C++ core libraries.

## For rpicam-apps Users

- ✅ TAPPAS core C++ libraries: Installed automatically with rpicam-apps
- ❌ Python venv: Not needed
- ❌ GStreamer plugins: Not needed
- ❌ Switching between venvs: Not needed

See `../rpicam/README.md` for rpicam-apps setup.

## More Information

- TAPPAS docs: https://github.com/hailo-ai/tappas
- See `../../docs/DEVELOPMENT.md` for Trixie compatibility status

