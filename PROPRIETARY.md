# Proprietary Components

This is the **open-source core** of FilaOps. The following components are proprietary and **NOT included** in this repository.

---

## What's NOT in This Repo

### 🤖 ML Pricing Engine
**Status:** Proprietary  
**Description:** Machine learning models for accurate cost estimation and quote generation.

**What we DON'T share:**
- ML model architecture and hyperparameters
- Training datasets and data sources
- Model training code and pipelines
- Inference optimization techniques
- Pricing algorithms and formulas
- Cost calculation logic
- Margin and markup strategies

**Why proprietary:** These models represent years of R&D and provide competitive accuracy for production manufacturing quotes.

---

### ⚙️ Manufacturing Integrations
**Status:** Proprietary  
**Description:** Deep integrations with 3D printing hardware and software.

**What we DON'T share:**
- BambuStudio CLI integration code
- Automated slicer configuration
- G-code analysis and parsing tools
- Real-time printer monitoring systems
- Fleet management automation
- Print failure detection algorithms

**Why proprietary:** These integrations require specialized knowledge and provide significant operational advantages.

---

### 📊 Advanced Analytics
**Status:** Proprietary  
**Description:** ML-powered business intelligence and predictive analytics.

**What we DON'T share:**
- Advanced dashboard implementations
- Predictive inventory models
- Production optimization algorithms
- Customer behavior analytics
- Demand forecasting models
- Quality control ML models

**Why proprietary:** These analytics drive operational efficiency and provide competitive insights.

---

### 🌐 Quote Portal Backend (Production)
**Status:** Proprietary  
**Description:** The production quote generation service with real pricing.

**What we DON'T share:**
- Multi-material pricing calculator (production version)
- Time estimation ML models
- Cost engine API (port 8001 in our stack)
- Slicing service integration
- Real-time inventory availability checks
- Shipping cost optimization

**Why proprietary:** This is the "secret sauce" that makes quotes accurate and profitable.

**What we DO share:** A [mock API server](./mock-api/) that parses real 3MF files but returns fake pricing. Perfect for UI development!

---

## What IS in This Repo

✅ **Core ERP Functionality**
- Product catalog and SKU management
- Bill of Materials (multi-level BOM)
- Inventory management with FIFO tracking
- Sales order processing
- Production order workflow
- Serial/lot traceability
- MRP (Material Requirements Planning)

✅ **Manufacturing Features**
- Work center management
- Routing and operation sequences
- Time tracking
- Basic capacity planning

✅ **Integration Framework**
- Stripe payment processing
- EasyPost shipping
- Squarespace sync (coming soon)
- QuickBooks integration (coming soon)

✅ **Developer Tools**
- Database schema and migrations
- API framework (FastAPI)
- Mock API for quote portal development
- Test suite and documentation

✅ **Documentation**
- Architecture diagrams (for open-source components)
- API documentation
- Database schema
- Contributor guidelines

---

## FilaOps Pro & Enterprise

We're building hosted solutions with the full feature set:

| Feature | Open Source | Pro | Enterprise |
|---------|-------------|-----|------------|
| Core ERP | ✅ | ✅ | ✅ |
| Inventory & MRP | ✅ | ✅ | ✅ |
| Serial/Lot Traceability | ✅ | ✅ | ✅ |
| **Customer Quote Portal** | Mock only | ✅ | ✅ |
| **Multi-Material Quoting** | Mock only | ✅ | ✅ |
| **ML Time Estimation** | ❌ | ❌ | ✅ |
| **Printer Fleet Management** | ❌ | ❌ | ✅ |
| **Advanced Analytics** | ❌ | ❌ | ✅ |
| **Priority Support** | ❌ | ✅ | ✅ |
| **Hosting & Updates** | Self-hosted | Hosted | Hosted |

**Coming:** Q2 2026  
**Contact:** hello@blb3dprinting.com  
**Updates:** Star/watch this repo to get notified

---

## Contributing to Open-Source Features

We welcome contributions to the open-source components! Here's what you can work on:

### High-Impact Areas
- 🎨 **Quote Portal UI** - Using the mock API (see [CONTRIBUTING.md](CONTRIBUTING.md))
- 📱 **Mobile Responsiveness** - Making the UI work on all devices
- ♿ **Accessibility** - WCAG compliance, keyboard navigation, screen readers
- 🐛 **Bug Fixes** - Squashing issues in the core ERP
- 📖 **Documentation** - Improving guides and API docs
- 🧪 **Testing** - Adding test coverage

### What You Can't Contribute To
- ❌ ML model improvements (not in repo)
- ❌ Pricing algorithm changes (not in repo)
- ❌ Production quote API (not in repo)
- ❌ BambuStudio integration (not in repo)

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and how to get started!

---

## Licensing

### Open-Source Components
This repository is licensed under the [Business Source License 1.1](LICENSE).

**Key points:**
- ✅ Free to use, modify, and distribute
- ✅ Can use for commercial purposes
- ❌ Cannot sell hosted FilaOps as a service (see "Usage Limitations" in LICENSE)
- ⏰ After 4 years, code converts to Apache 2.0

### Proprietary Components
The components listed above are **NOT open-source** and are covered by separate commercial licenses.

- **Source code:** Not publicly available
- **Usage:** Available only through FilaOps Pro/Enterprise
- **License:** Proprietary commercial license

---

## Intellectual Property

### What This Repo Contains
The code in this repository represents the open-source **framework** for a 3D print farm ERP. It does not include the machine learning models, pricing algorithms, or specialized integrations that provide competitive advantages.

### What's Protected
- **Patents (pending):** ML-based print time estimation, multi-material cost optimization
- **Trade Secrets:** Pricing formulas, training datasets, model architectures
- **Copyright:** All proprietary code and documentation
- **Trademarks:** FilaOps™, BLB3D™

---

## FAQ

### Q: Will the proprietary components ever be open-sourced?
**A:** We're committed to keeping the core ERP open-source. We may open-source additional components over time, but the ML models and pricing engine will likely remain proprietary as they represent significant R&D investment.

### Q: Can I fork this repo and add my own pricing logic?
**A:** Absolutely! That's the point of open-source. You can build your own pricing engine, use the mock API as a template, and customize FilaOps for your needs. Just follow the BSL 1.1 license terms.

### Q: Why split open-source and proprietary?
**A:** This approach lets us:
1. Build a community around the core ERP
2. Enable customization and contributions
3. Sustain development through commercial offerings
4. Protect the R&D investment in ML/pricing

### Q: How can I get access to the proprietary features?
**A:** Sign up for the waitlist: hello@blb3dprinting.com

### Q: Can I hire you to customize the open-source version for my shop?
**A:** Yes! Contact us for consulting services.

---

## Support

### For Open-Source Users
- **Issues:** [GitHub Issues](https://github.com/Blb3D/filaops/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Blb3D/filaops/discussions)
- **Docs:** See `/docs` folder

### For Pro/Enterprise
- **Email:** hello@blb3dprinting.com
- **Priority Support:** Included with Pro/Enterprise
- **SLA:** Guaranteed response times

---

## Roadmap

### Open-Source Roadmap (Public)
- ✅ Core ERP (Products, BOMs, Orders, Inventory)
- ✅ Production Orders with Operation Tracking
- ✅ Serial/Lot Traceability
- ✅ Mock API for Quote Portal
- 🔄 Squarespace Integration
- 🔄 QuickBooks Integration
- 📅 Advanced Reporting (Q1 2026)
- 📅 Multi-tenant Support (Q2 2026)

### Proprietary Roadmap (Private)
Details available to Pro/Enterprise customers.

---

## ⚠️ Production Deployment Requirements

**For commercial/SaaS hosting**, the following technical requirements must be met before deploying to production:

### Frontend Build Configuration

**Current Status**: Community edition uses **development mode builds** (unminified) which is:
- ✅ Acceptable for self-hosted/community deployments
- ❌ **NOT acceptable for SaaS/public hosting**

**Reason**: ~30 React components have temporal dead zone errors that only manifest in production builds. Development builds work around this but expose:
- Full source code and business logic
- Unobfuscated API patterns
- 2x larger bundle size

**Required Before SaaS Launch:**
1. Fix all useCallback/useEffect timing issues (6-8 hours)
2. Enable production minification
3. Disable source maps in production
4. Add build validation to CI/CD

See: `frontend/PRODUCTION_BUILD_BLOCKED.md` and `docs/SAAS_TIERING_PLAN.md`

---

**Questions?** Open a [Discussion](https://github.com/Blb3D/filaops/discussions) or email hello@blb3dprinting.com

---

*This document clarifies the boundary between open-source and proprietary components of FilaOps. Last updated: December 2025*
