# Contributing to FilaOps

Thanks for your interest in contributing to FilaOps! This guide will help you get started.

## Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Start the mock API server** for development
4. **Make your changes** and test locally
5. **Submit a pull request**

## Development Setup

### Mock API Server

The mock API provides a development environment without needing the proprietary backend:
```bash
cd mock-api
npm install
npm start
```

The mock server runs on:
- Port 8000: 3MF analysis endpoint
- Port 8001: Quote generation and materials endpoints

### What the Mock API Does

**Real functionality:**
- Parses 3MF files (geometry, materials, thumbnails)
- Detects multi-material prints
- Extracts color information

**Simulated functionality:**
- Material weights (estimated, not sliced)
- Print times (rough estimates)
- Pricing (fake rates to protect business logic)

## Areas for Contribution

### High Priority

1. **3D Viewer Instance Rendering**
   - BambuStudio 3MF files with instances don't render correctly
   - Need to parse instance transforms from metadata

2. **Multi-Material Color Selection UX**
   - Improve color picker interface
   - Add real-time cost feedback
   - Better mobile experience

### Other Areas

- UI/UX improvements
- Accessibility features
- Mobile responsiveness
- Documentation
- Bug fixes

## What's NOT in This Repo

FilaOps has a tiered architecture:

- **Open Source (this repo):** Core ERP, mock API, documentation
- **Pro (proprietary):** Quote portal, admin dashboard, integrations
- **Enterprise (proprietary):** ML pricing models, BambuStudio integration, production slicing

See [PROPRIETARY.md](PROPRIETARY.md) for details.

## Code Style

- Follow existing code patterns
- Write clear commit messages
- Add comments for complex logic
- Test your changes locally

## Submitting Changes

1. Create a feature branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Test against mock API
4. Commit with clear message: `git commit -m "Add feature: description"`
5. Push to your fork: `git push origin feature/your-feature-name`
6. Open a Pull Request on GitHub

## Questions?

- **Issues:** [GitHub Issues](https://github.com/Blb3D/filaops/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Blb3D/filaops/discussions)
- **Email:** hello@blb3dprinting.com

## License

By contributing, you agree that your contributions will be licensed under the Business Source License 1.1 (converts to Apache 2.0 after 4 years).

---

Thank you for contributing to FilaOps! 🎉
