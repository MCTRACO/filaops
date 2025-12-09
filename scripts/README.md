# FilaOps Scripts

Scripts for managing GitHub updates and viral launch.

## Scripts

### `update-readme-docker.ps1`
Updates README.md with Docker hero section highlighting one-command deployment.

**Usage:**
```powershell
.\scripts\update-readme-docker.ps1
```

### `add-github-topics.ps1`
Adds GitHub topics to the repository for better discoverability.

**Requirements:**
- GitHub CLI (gh) installed
- Authenticated: `gh auth login`

**Usage:**
```powershell
.\scripts\add-github-topics.ps1
```

**Topics added:**
- 3d-printing, erp, docker, manufacturing
- inventory-management, print-farm, mrp, bom
- fastapi, react, open-source, self-hosted
- manufacturing-software, production-planning, material-requirements-planning

### `create-release.ps1`
Creates a GitHub release with release notes.

**Requirements:**
- GitHub CLI (gh) installed
- Authenticated: `gh auth login`

**Usage:**
```powershell
# Create release
.\scripts\create-release.ps1

# Create draft release
.\scripts\create-release.ps1 -Draft

# Custom version/title
.\scripts\create-release.ps1 -Version "v1.0.0" -Title "My Release"
```

### `viral-launch.ps1`
All-in-one script that runs all updates.

**Usage:**
```powershell
# Run everything
.\scripts\viral-launch.ps1

# Skip release creation
.\scripts\viral-launch.ps1 -SkipRelease

# Create draft release
.\scripts\viral-launch.ps1 -DraftRelease
```

## Prerequisites

### GitHub CLI Installation

1. **Windows:**
   ```powershell
   winget install --id GitHub.cli
   ```

2. **macOS:**
   ```bash
   brew install gh
   ```

3. **Linux:**
   ```bash
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update
   sudo apt install gh
   ```

### Authentication

```powershell
gh auth login
```

Follow the prompts to authenticate.

### Verify Setup

```powershell
gh auth status
gh repo view Blb3D/filaops
```

## Manual Alternatives

If you don't want to use GitHub CLI:

1. **README Update:** Run `update-readme-docker.ps1` or edit manually
2. **Topics:** Go to https://github.com/Blb3D/filaops/settings → Topics
3. **Release:** Go to https://github.com/Blb3D/filaops/releases/new

## Notes

- Scripts are PowerShell (.ps1) files
- Run from the repository root directory
- Some scripts require GitHub CLI for full functionality
- All scripts provide manual alternatives if CLI is not available

