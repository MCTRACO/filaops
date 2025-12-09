# Open Source Release Checklist

Complete checklist to get FilaOps ready for public release as a fully functional open source ERP.

---

## 🎯 Phase 1: Critical Functionality (Must Have)

### Database & Setup
- [ ] **Verify database setup script works end-to-end**
  - [ ] Test `scripts/fresh_database_setup.py` on clean system
  - [ ] Verify all tables are created correctly
  - [ ] Verify default admin user is created
  - [ ] Test database connection from both backend and frontend
  - [ ] Document any manual SQL scripts that need to be run

- [ ] **Environment configuration**
  - [ ] Create `.env.example` with all required variables
  - [ ] Document all environment variables in README
  - [ ] Test with minimal configuration
  - [ ] Verify default values work correctly

### Core ERP Features
- [ ] **Product/Item Management**
  - [ ] Create new items (all types: finished goods, components, supplies, materials)
  - [ ] Edit existing items
  - [ ] SKU auto-generation works correctly
  - [ ] Material type and color selection works
  - [ ] Category management works

- [ ] **BOM Management**
  - [ ] Create BOMs for finished goods
  - [ ] Add/remove BOM lines
  - [ ] Unit of measure handling
  - [ ] Cost-only flags work
  - [ ] Multi-level BOM support verified

- [ ] **Inventory Management**
  - [ ] View inventory levels
  - [ ] Inventory transactions (receipts, issues, transfers, adjustments)
  - [ ] Low stock alerts work
  - [ ] MRP-driven low stock detection
  - [ ] Inventory locations work

- [ ] **Sales Orders**
  - [ ] Create sales orders
  - [ ] Add line items
  - [ ] Order status tracking
  - [ ] Order detail page (Command Center) works
  - [ ] MRP explosion on orders works
  - [ ] Material shortage detection works

- [ ] **Production Orders**
  - [ ] Create production orders from sales orders
  - [ ] Material reservation works
  - [ ] Production status tracking
  - [ ] Operation tracking
  - [ ] Complete production workflow

- [ ] **Purchasing**
  - [ ] Low stock alerts show MRP requirements
  - [ ] Purchase order creation
  - [ ] Vendor management

- [ ] **Shipping**
  - [ ] Create shipments
  - [ ] Production status validation
  - [ ] Multi-carrier support
  - [ ] Packing slips

### Manufacturing
- [ ] **Work Centers**
  - [ ] Create/edit work centers
  - [ ] Resource management
  - [ ] Capacity planning

- [ ] **Routings**
  - [ ] Create/edit routings
  - [ ] Operation sequences
  - [ ] Time standards
  - [ ] Cost calculation

### Dashboard
- [ ] **Admin Dashboard**
  - [ ] KPIs load correctly
  - [ ] Overdue orders display
  - [ ] Low stock alerts accurate
  - [ ] Revenue metrics work
  - [ ] No "fail to fetch" errors

---

## 🐛 Phase 2: Bug Fixes & Known Issues

### High Priority Bugs
- [ ] **Hardcoded location_id=1**
  - [ ] Make inventory locations configurable
  - [ ] Remove hardcoded values from inventory endpoints
  - [ ] Add default location configuration

- [ ] **Scrap location fallback**
  - [ ] Proper scrap location handling
  - [ ] Remove default to location_id=1

- [ ] **Zero inventory blocking**
  - [ ] Decide if production should block on zero inventory
  - [ ] Implement blocking or clear warning system

### Medium Priority
- [ ] **Tax calculation** (currently hardcoded to 0)
  - [ ] Add tax configuration
  - [ ] Calculate tax on orders

- [ ] **Email verification** (currently disabled)
  - [ ] Implement email verification flow
  - [ ] Or document that it's disabled for open source

### Low Priority
- [ ] **Type checker warnings** (SQLAlchemy false positives)
  - [ ] Add type ignore comments where needed
  - [ ] Or document that warnings can be ignored

---

## 📚 Phase 3: Documentation

### User Documentation
- [ ] **GETTING_STARTED.md**
  - [ ] Complete step-by-step setup
  - [ ] All prerequisites listed
  - [ ] Troubleshooting section
  - [ ] Common issues and solutions

- [ ] **HOW_IT_WORKS.md**
  - [ ] Complete workflow documentation
  - [ ] Product → BOM → Order → Production flow
  - [ ] MRP explanation
  - [ ] Inventory management guide

- [ ] **API Documentation**
  - [ ] Verify FastAPI docs are complete
  - [ ] Add examples for all endpoints
  - [ ] Document authentication
  - [ ] Document error responses

### Developer Documentation
- [ ] **CONTRIBUTING.md**
  - [ ] Development setup
  - [ ] Code style guidelines
  - [ ] Testing guidelines
  - [ ] Pull request process

- [ ] **ARCHITECTURE.md**
  - [ ] System architecture overview
  - [ ] Database schema
  - [ ] API design principles
  - [ ] Frontend structure

### README Updates
- [ ] **README.md**
  - [ ] Feature list is accurate
  - [ ] Quick start works
  - [ ] Screenshots or demo video link
  - [ ] License information
  - [ ] Links to all documentation

---

## 🧪 Phase 4: Testing

### Manual Testing
- [ ] **End-to-End Workflow Test**
  - [ ] Create product with BOM
  - [ ] Create sales order
  - [ ] Run MRP explosion
  - [ ] Create production order
  - [ ] Start production
  - [ ] Complete production
  - [ ] Create shipment
  - [ ] Verify inventory updates correctly

- [ ] **Edge Cases**
  - [ ] Zero inventory scenarios
  - [ ] Negative inventory (if allowed)
  - [ ] Large quantities
  - [ ] Special characters in names/SKUs
  - [ ] Very long descriptions

- [ ] **Error Handling**
  - [ ] Invalid data entry
  - [ ] Missing required fields
  - [ ] Database connection failures
  - [ ] API errors display correctly

### Automated Testing
- [ ] **Backend Tests**
  - [ ] Unit tests for core services
  - [ ] API endpoint tests
  - [ ] Database model tests

- [ ] **Frontend Tests**
  - [ ] Component tests
  - [ ] Integration tests
  - [ ] E2E tests (if Playwright is set up)

---

## 🔒 Phase 5: Security & Best Practices

### Security
- [ ] **Authentication**
  - [ ] Password requirements enforced
  - [ ] JWT tokens expire correctly
  - [ ] Refresh tokens work
  - [ ] Password reset flow works (if implemented)

- [ ] **Authorization**
  - [ ] Admin-only endpoints protected
  - [ ] User data isolation (if multi-user)
  - [ ] SQL injection prevention verified

- [ ] **Secrets Management**
  - [ ] No secrets in code
  - [ ] `.env` in `.gitignore`
  - [ ] Default passwords documented

### Code Quality
- [ ] **Code Review**
  - [ ] Remove debug code
  - [ ] Remove commented-out code (or document why)
  - [ ] Consistent code style
  - [ ] No hardcoded values (use config)

- [ ] **Dependencies**
  - [ ] All dependencies up to date
  - [ ] No known security vulnerabilities
  - [ ] License compatibility checked

---

## 🚀 Phase 6: Deployment & Distribution

### Deployment Preparation
- [ ] **Production Configuration**
  - [ ] Production settings documented
  - [ ] Database backup/restore procedures
  - [ ] Environment variable documentation
  - [ ] SSL/HTTPS setup guide

- [ ] **Docker (Optional but Recommended)**
  - [ ] Dockerfile for backend
  - [ ] Dockerfile for frontend
  - [ ] docker-compose.yml
  - [ ] Docker documentation

### Distribution
- [ ] **GitHub Repository**
  - [ ] Clean commit history (or squash)
  - [ ] Proper tags/releases
  - [ ] Release notes
  - [ ] GitHub Actions for CI (optional)

- [ ] **Package Management**
  - [ ] Python package structure (if distributing as package)
  - [ ] npm package (if distributing frontend separately)

---

## 📋 Phase 7: Polish & UX

### User Experience
- [ ] **UI/UX Review**
  - [ ] Consistent styling across all pages
  - [ ] Loading states for all async operations
  - [ ] Error messages are user-friendly
  - [ ] Success messages confirm actions
  - [ ] Mobile responsiveness (if applicable)

- [ ] **Accessibility**
  - [ ] Keyboard navigation works
  - [ ] Screen reader compatibility (basic)
  - [ ] Color contrast meets standards

### Performance
- [ ] **Performance Testing**
  - [ ] Page load times acceptable
  - [ ] API response times acceptable
  - [ ] Database queries optimized
  - [ ] Large dataset handling

---

## 🎁 Phase 8: Open Source Essentials

### Legal & Licensing
- [ ] **License File**
  - [ ] LICENSE file present
  - [ ] License type chosen (BSL 1.1 mentioned in README)
  - [ ] License headers in code (if required)

- [ ] **Contributing Guidelines**
  - [ ] CONTRIBUTING.md complete
  - [ ] Code of conduct (optional but recommended)
  - [ ] Issue templates
  - [ ] Pull request template

### Community
- [ ] **Community Setup**
  - [ ] GitHub Discussions enabled
  - [ ] Issue labels configured
  - [ ] README has community section
  - [ ] Discord/forum link (if applicable)

---

## ✅ Phase 9: Final Verification

### Pre-Release Checklist
- [ ] **All Critical Features Work**
  - [ ] Complete order-to-ship workflow tested
  - [ ] No blocking bugs
  - [ ] Documentation complete

- [ ] **Code Quality**
  - [ ] No obvious bugs
  - [ ] Code is maintainable
  - [ ] Comments where needed

- [ ] **Documentation Quality**
  - [ ] All docs are accurate
  - [ ] Examples work
  - [ ] No broken links

- [ ] **User Experience**
  - [ ] First-time user can get started
  - [ ] Common tasks are intuitive
  - [ ] Error messages are helpful

---

## 🎯 Priority Order

### Must Complete Before Release:
1. ✅ Phase 1: Critical Functionality
2. ✅ Phase 2: High Priority Bugs
3. ✅ Phase 3: Core Documentation (GETTING_STARTED, README)
4. ✅ Phase 4: Basic Manual Testing
5. ✅ Phase 5: Security Basics
6. ✅ Phase 9: Final Verification

### Should Complete (But Can Release Without):
- Phase 2: Medium/Low Priority Bugs
- Phase 3: Advanced Documentation
- Phase 4: Automated Testing
- Phase 6: Docker/Deployment
- Phase 7: Polish & UX
- Phase 8: Community Setup

---

## 📝 Notes

- **License System**: Currently disabled - keep disabled for open source release
- **Pro Features**: Analytics and other Pro features should show upgrade prompts, not errors
- **Database**: Ensure `fresh_database_setup.py` works for new users
- **Default Data**: Consider adding sample data for demo purposes

---

## 🚦 Current Status Assessment

Based on codebase review:

**✅ Likely Complete:**
- Core ERP functionality (based on MRP refactor completion)
- Database models and schemas
- Basic API endpoints
- Frontend UI components

**⚠️ Needs Verification:**
- End-to-end workflow testing
- Database setup script reliability
- Documentation accuracy
- Bug fixes for known issues

**❌ Needs Work:**
- Hardcoded values (location_id, etc.)
- Tax calculation
- Email verification
- Comprehensive testing
- Documentation polish

---

**Last Updated:** 2025-12-09
**Target Release Date:** TBD

