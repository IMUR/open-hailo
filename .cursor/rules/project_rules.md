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
   - `README.md` - Project overview and quick start
   - `docs/SETUP.md` - Installation and setup
   - `docs/BUILD.md` - Build instructions
   - `docs/API.md` - API reference and examples
   - `docs/DEVELOPMENT.md` - Developer guide and project structure
   - `docs/CONTRIBUTING.md` - Contribution guidelines and project rules

## File Organization

### Scripts
- All scripts must go in `/scripts/` subdirectories:
  - `/scripts/setup/` - Installation and configuration
  - `/scripts/build/` - Compilation and building
  - `/scripts/preview/` - Camera and visualization
  - `/scripts/utils/` - Testing and utilities

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
