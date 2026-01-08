# In-App Upgrade System Design

## Overview

This document describes the in-app upgrade system for FilaOps, designed to make version updates safe and accessible for non-technical users.

## Current State

FilaOps already has:

- Version checker (`/api/v1/system/version`)
- Update check endpoint (`/api/v1/system/updates/check`)
- Frontend banner notification for new versions

## Proposed Enhancements

### 1. One-Click Update Button

**Location:** Settings page and update notification banner

**Flow:**

```text
[Update Available Banner]
     │
     ├─► "Update Now" button
     │        │
     │        ▼
     │   [Confirmation Modal]
     │   "Update to v2.1.0?"
     │   - Show release notes summary
     │   - Estimated time: ~5 minutes
     │   - "Your data will be backed up automatically"
     │        │
     │        ├─► "Update" → Start update process
     │        └─► "Later" → Dismiss (remind in 24h)
     │
     └─► "View Release Notes" → Opens GitHub release page
```

### 2. Pre-Update Backup

**Automatic backup before any update:**

```python
# backend/app/services/backup_service.py

class BackupService:
    def create_backup(self) -> BackupResult:
        """
        Creates a full database backup.
        Returns backup file path and metadata.
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = f"backups/filaops_backup_{timestamp}.sql"
        
        # pg_dump to file
        # Compress with gzip
        # Return metadata
        
    def list_backups(self) -> List[BackupInfo]:
        """List available backups with timestamps and sizes."""
        
    def restore_backup(self, backup_id: str) -> bool:
        """Restore from a specific backup."""
        
    def cleanup_old_backups(self, keep_count: int = 5):
        """Remove old backups, keeping most recent N."""
```

**API Endpoints:**

```text
POST /api/v1/system/backup          → Create backup
GET  /api/v1/system/backups         → List backups
POST /api/v1/system/restore/{id}    → Restore from backup
```

### 3. Update Process

**Backend update orchestration:**

```python
# backend/app/services/update_service.py

class UpdateService:
    def check_for_updates(self) -> UpdateInfo:
        """Check GitHub for newer versions."""
        
    def start_update(self, target_version: str) -> UpdateJob:
        """
        Initiates update process:
        1. Create backup
        2. Set maintenance mode
        3. Return job ID for status polling
        """
        
    def get_update_status(self, job_id: str) -> UpdateStatus:
        """
        Returns current update status:
        - pending, backing_up, downloading, applying, migrating, 
          restarting, verifying, complete, failed
        """
        
    def rollback(self, job_id: str) -> bool:
        """Rollback to pre-update state if update failed."""
```

**Update execution (runs outside main app):**

```python
# scripts/perform_update.py

def perform_update(target_version: str, backup_file: str):
    """
    Executed by Docker or systemd, not the main app.
    
    Steps:
    1. Stop backend container
    2. Git fetch && git checkout {target_version}
    3. Rebuild containers
    4. Run migrations
    5. Start containers
    6. Health check
    7. Update status file
    """
```

### 4. Frontend Update UI

**Components:**

```typescript
// frontend/src/components/UpdateManager.tsx

interface UpdateState {
  status: 'idle' | 'checking' | 'available' | 'updating' | 'complete' | 'failed';
  currentVersion: string;
  availableVersion?: string;
  updateJob?: {
    id: string;
    step: string;
    progress: number;
    message: string;
  };
  error?: string;
}

const UpdateManager: React.FC = () => {
  // Polls /api/v1/system/updates/check on mount and every 24h
  // Shows banner when update available
  // Handles update flow with progress modal
};
```

**Update Progress Modal:**

```text
┌─────────────────────────────────────────────┐
│  Updating FilaOps to v2.1.0                 │
├─────────────────────────────────────────────┤
│                                             │
│  [████████████░░░░░░░░] 60%                │
│                                             │
│  ✓ Backup created                          │
│  ✓ Downloaded update                       │
│  ● Applying migrations...                  │
│  ○ Restarting services                     │
│  ○ Verifying installation                  │
│                                             │
│  Do not close this window.                 │
│                                             │
└─────────────────────────────────────────────┘
```

### 5. Handling Breaking Changes (v1.x → v2.x)

**Detection:**

```python
def is_breaking_update(current: str, target: str) -> bool:
    """Check if major version changed."""
    current_major = int(current.split('.')[0])
    target_major = int(target.split('.')[0])
    return target_major > current_major
```

**Breaking Change Flow:**

```text
[Update Available: v2.0.0]
     │
     ▼
[Breaking Change Warning Modal]
┌─────────────────────────────────────────────┐
│  ⚠️  Major Update Available                 │
├─────────────────────────────────────────────┤
│                                             │
│  v2.0.0 includes breaking changes:          │
│                                             │
│  • Database changed from SQL Server         │
│    to PostgreSQL                            │
│  • Your existing data cannot be             │
│    automatically migrated                   │
│                                             │
│  Options:                                   │
│                                             │
│  [Start Fresh]  [Export Data]  [Cancel]     │
│                                             │
│  Need help? Contact support or visit        │
│  GitHub Discussions.                        │
│                                             │
└─────────────────────────────────────────────┘
```

**Export Data option:**

- Exports customers, items, orders to CSV/JSON
- User can manually re-import after upgrade
- Not a full migration, but preserves critical data

### 6. Version Nagware

**Escalating notifications for outdated versions:**

| Days Behind | Behavior |
| ----------- | -------- |
| 0-7 | Subtle banner, dismissable for 7 days |
| 8-30 | Yellow warning banner, dismissable for 24h |
| 31-60 | Orange banner with "Known issues may affect you" |
| 60+ | Red persistent banner, modal on login |

```python
def get_nag_level(current: str, latest: str, last_dismiss: datetime) -> NagLevel:
    """Determine how aggressively to nag about updates."""
    
    versions_behind = count_versions_between(current, latest)
    days_since_dismiss = (datetime.now() - last_dismiss).days
    
    # Logic to return: none, subtle, warning, urgent, critical
```

### 7. Database Schema

```sql
-- Track update history
CREATE TABLE system_updates (
    id SERIAL PRIMARY KEY,
    from_version VARCHAR(20) NOT NULL,
    to_version VARCHAR(20) NOT NULL,
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    status VARCHAR(20) NOT NULL,  -- pending, running, complete, failed, rolled_back
    backup_file VARCHAR(255),
    error_message TEXT,
    initiated_by INTEGER REFERENCES users(id)
);

-- Track backup files
CREATE TABLE system_backups (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    size_bytes BIGINT NOT NULL,
    version VARCHAR(20) NOT NULL,
    type VARCHAR(20) NOT NULL,  -- manual, pre_update, scheduled
    notes TEXT
);

-- User dismissal tracking (existing, may need to extend)
ALTER TABLE users ADD COLUMN update_dismissed_at TIMESTAMP;
ALTER TABLE users ADD COLUMN update_dismissed_version VARCHAR(20);
```

### 8. Implementation Phases

**Phase 1: Backup System** (1-2 days)

- [ ] BackupService with pg_dump
- [ ] API endpoints for backup/restore
- [ ] Settings page UI for manual backup/restore
- [ ] Migration for system_backups table

**Phase 2: Update Orchestration** (2-3 days)

- [ ] UpdateService with GitHub integration
- [ ] Update script that runs outside main process
- [ ] Status file for progress tracking
- [ ] Migration for system_updates table

**Phase 3: Frontend Integration** (1-2 days)

- [ ] UpdateManager component
- [ ] Progress modal with polling
- [ ] Settings page update section
- [ ] Enhanced notification banner

**Phase 4: Breaking Change Handling** (1 day)

- [ ] Major version detection
- [ ] Breaking change modal
- [ ] Data export functionality
- [ ] "Start Fresh" workflow

**Phase 5: Nagware** (0.5 days)

- [ ] Nag level calculation
- [ ] Dismissal tracking
- [ ] Escalating UI treatments

### 9. Security Considerations

- Backup files stored outside web root
- Backup API requires admin role
- Update API requires admin role
- Git operations use HTTPS (no SSH keys needed)
- No credentials stored in update scripts

### 10. Rollback Strategy

If update fails:

1. Detect failure via health check
2. Stop new containers
3. Restore from pre-update backup
4. Restart old containers (from backup image tag)
5. Notify user with error details

```python
def rollback(job_id: str):
    job = get_update_job(job_id)
    
    # Stop current containers
    docker_compose_down()
    
    # Checkout previous version
    git_checkout(job.from_version)
    
    # Restore database
    restore_backup(job.backup_file)
    
    # Rebuild and start
    docker_compose_up()
    
    # Update job status
    job.status = 'rolled_back'
    job.save()
```

---

## Summary

This system provides:

1. **Safety** - Automatic backups before every update
2. **Simplicity** - One-click updates from the UI
3. **Visibility** - Clear progress indication
4. **Recovery** - Easy rollback if something goes wrong
5. **Awareness** - Escalating notifications for outdated versions
6. **Breaking changes** - Special handling for major upgrades

The goal is to make updates so easy and safe that users actually do them, eliminating "stuck on v1.7 for 3 weeks" situations.
