# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.x.x   | :white_check_mark: |

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via:
- Email: [YOUR-EMAIL]
- GitHub Security Advisory: [Create a private advisory](https://github.com/Blb3D/filaops/security/advisories/new)

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You will receive a response within 48 hours. We take all security reports seriously.

---

## Official Distribution Channels

FilaOps is **ONLY** distributed through:

| Channel | URL | Verified |
|---------|-----|----------|
| GitHub Repository | https://github.com/Blb3D/filaops | ✅ |
| GitHub Releases | https://github.com/Blb3D/filaops/releases | ✅ |

### We Do NOT Distribute FilaOps Through:

- ❌ Direct zip downloads from `raw.githubusercontent.com`
- ❌ Third-party websites
- ❌ Email attachments
- ❌ Discord/forum file shares
- ❌ Any other GitHub account

**If you find FilaOps hosted elsewhere, it may be malicious.**

---

## Verifying Releases

All official releases include SHA256 checksums.

### Verify Your Download

**Linux/macOS:**
```bash
# Download the release and SHA256SUMS.txt
sha256sum -c SHA256SUMS.txt
```

**Windows (PowerShell):**
```powershell
Get-FileHash filaops-vX.X.X.zip -Algorithm SHA256
# Compare output to checksum in SHA256SUMS.txt
```

### GPG Verification (Optional)

Releases are signed with GPG. To verify:

```bash
# Import public key (one-time)
curl -s https://raw.githubusercontent.com/Blb3D/filaops/main/PUBLIC-KEY.asc | gpg --import

# Verify signature
gpg --verify SHA256SUMS.txt.sig SHA256SUMS.txt

# If valid, verify checksums
sha256sum -c SHA256SUMS.txt
```

**Key fingerprint:** `[FINGERPRINT WILL BE ADDED]`

---

## Known Threats

We maintain awareness of malicious forks and distribution channels targeting our users.

### Active Threats

| Repository | Status | Details |
|------------|--------|---------|
| `printertechn/filaops` | 🔴 MALICIOUS | Distributes malware via modified download links. Reported to GitHub. |

### Reporting Suspicious Forks

If you encounter a suspicious FilaOps fork or distribution:

1. **Do not download anything** from it
2. [Open an issue](https://github.com/Blb3D/filaops/issues/new) with the URL
3. Report directly to GitHub if it contains malware

---

## Security Hardening Measures

As of January 2026, FilaOps implements:

- ✅ SHA256 checksums on all releases
- ✅ GPG-signed checksum files
- ✅ Automated release pipeline via GitHub Actions
- ✅ Security warnings in README
- ✅ Public security policy (this document)
- ✅ Monitoring of known threats

---

## Incident Response

In the event of a security incident affecting FilaOps users:

1. Security advisory posted to GitHub
2. Affected versions clearly documented
3. Mitigation steps provided
4. Announcement in GitHub Discussions

---

## Contact

- **Security issues:** [YOUR-EMAIL] or GitHub Security Advisory
- **General questions:** [GitHub Discussions](https://github.com/Blb3D/filaops/discussions)
- **Maintainer:** Brandan Baker (@Blb3D)

---

*Last updated: January 18, 2026*