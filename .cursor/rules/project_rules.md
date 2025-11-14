# Project-Specific Rules for Open Hailo

## Documentation Management

### CRITICAL RULE: Always Update Existing Documentation
**Never create new documentation files if the content can be added to existing ones.**

1. **Before creating any document:**
   - Check all existing docs in `/docs/` directory
   - Determine if content belongs in an existing file
   - Only create new if topic is completely distinct

2. **When updating documentation:**
   - Maintain existing structure and formatting
   - Add content to appropriate sections
   - Update table of contents if present
   - Keep related information together

3. **If new document is necessary:**
   - It becomes the canonical source for that topic
   - All future related content goes there
   - Add reference in docs/README.md index
   - No temporary or duplicate files

4. **Document purposes:**
   - `README.md` - Project overview, quick start entry points, repository map
   - `docs/getting-started/quickstart.md` - Fast path install steps
   - `docs/getting-started/setup-details.md` - Deep-dive setup and environment notes
   - `docs/deployments/<name>.md` - Deployment-specific guidance (rpicam, python-direct, frigate, tappas, opencv-custom)
   - `docs/development/` - Build, API, contributor development workflows
   - `docs/operations/troubleshooting.md` - Runtime diagnostics and fixes
   - `CONTRIBUTING.md` (root) - Contribution guidelines and repository rules

## File Organization

### Scripts
- All scripts must live under `/scripts/` subdirectories:
  - `/scripts/setup/` - Installation, verification, diagnostics launching
  - `/scripts/driver/` - Driver acquisition, build, installation
  - `/scripts/diagnostics/` - Troubleshooting helpers
  - `/scripts/demos/` - Example/demo launchers
  - `/scripts/utils/` - Miscellaneous helpers (version checks, etc.)
  - `/scripts/build/` - Heavy build orchestration when required
- Deployment-specific install/launch logic belongs in `configs/<deployment>/install.sh`

### Code
- C++ examples in `/apps/`
- Test configurations in `/test/`
- Models in `/models/`

### Logs
- All log files must go to `/logs/`
- Add timestamps to log filenames
- No scattered log files in other directories

## No Temporary Files
- Don't create temporary documentation
- Don't create "summary" files that duplicate existing docs
- Don't create test files outside `/test/`
- Clean up any temporary files after use
