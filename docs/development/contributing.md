# Contributing to Open Hailo

First off, thank you for considering contributing to Open Hailo! It's people like you that make Open Hailo a great tool for the community.

## 📋 Project Rules & Guidelines

### Documentation Management
**IMPORTANT: Always update existing documentation instead of creating new documents.**
- Before creating any new document, check if the content belongs in an existing file
- If updating existing docs, maintain the current structure and style
- If a new document is absolutely necessary, it becomes the canonical source for that topic
- Avoid creating temporary or duplicate documentation files

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Include your system information** (OS version, kernel version, Hailo device model)
- **Include relevant logs** from `dmesg`, `hailortcli`, or your application

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any alternative solutions you've considered**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure your code follows the existing style
4. Update the documentation
5. Issue that pull request!

## Development Setup

```bash
# Clone your fork
git clone https://github.com/your-username/open-hailo.git
cd open-hailo

# Create a branch
git checkout -b feature/your-feature-name

# Make your changes
# Test thoroughly
cd apps/build
cmake .. && make
./device_test

# Commit your changes
git add .
git commit -m "Add your meaningful commit message"

# Push to your fork
git push origin feature/your-feature-name
```

## Code Style

### C/C++
- Use 4 spaces for indentation
- Keep lines under 100 characters when possible
- Use meaningful variable and function names
- Add comments for complex logic

### Documentation
- Use Markdown for documentation
- Include code examples where appropriate
- Keep language clear and concise

## Testing

Before submitting a PR:
1. Test on actual Hailo hardware if possible
2. Ensure the build script runs without errors
3. Verify device_test passes
4. Check for memory leaks with valgrind if applicable

## Areas We Need Help

- **Platform Support**: Testing and adapting for other Linux distributions
- **Documentation**: Improving guides, adding tutorials
- **Examples**: More sample applications showcasing different use cases
- **Performance**: Optimization and benchmarking
- **CI/CD**: Setting up automated testing

## Community

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members

## Questions?

Feel free to open an issue with the "question" label or reach out on the Hailo Community Forum.

Thank you for contributing! 🎉
