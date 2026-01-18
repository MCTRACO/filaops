# GPG Key Setup for Signed Releases

This guide helps you set up GPG signing for FilaOps releases.

## Step 1: Generate a GPG Key

```bash
# Generate a new key
gpg --full-generate-key

# When prompted:
# - Key type: RSA and RSA (default)
# - Key size: 4096
# - Expiration: 0 (does not expire) or set your preference
# - Real name: Brandan Baker
# - Email: [your-email]
# - Comment: FilaOps Release Signing Key
# - Passphrase: [choose a strong passphrase - you'll need this for GitHub]
```

## Step 2: Get Your Key ID

```bash
# List your keys
gpg --list-secret-keys --keyid-format LONG

# Output looks like:
# sec   rsa4096/ABCD1234EFGH5678 2026-01-18 [SC]
#       1234567890ABCDEF1234567890ABCDEF12345678
# uid                 [ultimate] Brandan Baker (FilaOps Release Signing Key) <email>
# ssb   rsa4096/XXXXXXXXXXXX 2026-01-18 [E]

# Your key ID is: ABCD1234EFGH5678 (the part after rsa4096/)
# Your fingerprint is the long hex string on the second line
```

## Step 3: Export Your Public Key

```bash
# Export public key (replace with your key ID)
gpg --armor --export ABCD1234EFGH5678 > PUBLIC-KEY.asc

# This file goes in your repo root
```

## Step 4: Export Private Key for GitHub Actions

```bash
# Export private key (keep this SECRET)
gpg --armor --export-secret-keys ABCD1234EFGH5678 > private-key.asc

# ⚠️ DO NOT commit this file
# ⚠️ Delete after adding to GitHub Secrets
```

## Step 5: Add Secrets to GitHub

1. Go to your repo: `github.com/Blb3D/filaops`
2. Settings → Secrets and variables → Actions
3. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `GPG_PRIVATE_KEY` | Contents of `private-key.asc` |
| `GPG_PASSPHRASE` | Your GPG passphrase |

## Step 6: Commit Public Key to Repo

```bash
# Add public key to repo
git add PUBLIC-KEY.asc
git commit -m "Add GPG public key for release verification"
git push
```

## Step 7: Update SECURITY.md

Add your key fingerprint to SECURITY.md:

```markdown
**Key fingerprint:** `1234 5678 90AB CDEF 1234  5678 90AB CDEF 1234 5678`
```

Get fingerprint:
```bash
gpg --fingerprint ABCD1234EFGH5678
```

## Step 8: Test the Workflow

```bash
# Create a test tag
git tag -a v0.0.1-test -m "Test release"
git push origin v0.0.1-test

# Check GitHub Actions for the release workflow
# Delete test release/tag after confirming it works
```

---

## Verifying Everything Works

### On Your Machine

```bash
# Sign a test file
echo "test" > test.txt
gpg --armor --detach-sign test.txt

# Verify it
gpg --verify test.txt.asc test.txt

# Clean up
rm test.txt test.txt.asc
```

### On GitHub

After pushing a tag:
1. Check Actions tab for workflow run
2. Check Releases for:
   - Release artifacts (tar.gz files)
   - SHA256SUMS.txt
   - SHA256SUMS.txt.sig (GPG signature)

---

## Cleanup

```bash
# Delete the private key file (IMPORTANT!)
rm private-key.asc

# The private key is now only in:
# 1. Your local GPG keyring
# 2. GitHub Secrets (encrypted)
```

---

## Key Management Best Practices

1. **Backup your private key** securely (encrypted USB, password manager, etc.)
2. **Use a strong passphrase** — this protects the key even if stolen
3. **Set a calendar reminder** if your key has an expiration date
4. **Revoke immediately** if you suspect compromise

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `gpg --list-secret-keys --keyid-format LONG` | List your keys |
| `gpg --armor --export KEY_ID > public.asc` | Export public key |
| `gpg --armor --export-secret-keys KEY_ID > private.asc` | Export private key |
| `gpg --fingerprint KEY_ID` | Get fingerprint |
| `gpg --verify file.sig file` | Verify signature |
| `gpg --armor --detach-sign file` | Sign a file |