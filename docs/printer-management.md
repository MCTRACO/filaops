# Printer Management

FilaOps supports brand-agnostic printer management, allowing you to track and monitor 3D printers from various manufacturers in a unified interface.

## Supported Printer Brands

| Brand | Discovery | Connection Test | Live Status (Pro) |
|-------|-----------|-----------------|-------------------|
| BambuLab | IP Probe | Port 8883 (MQTT) | MQTT + Camera |
| Klipper/Moonraker | IP Probe | Port 7125 | Moonraker API |
| OctoPrint | IP Probe | Port 5000 | REST API |
| Prusa Connect | Manual | HTTP/HTTPS | Prusa Link API |
| Creality | Manual | HTTP/HTTPS | Cloud API |
| Generic | Manual | HTTP/HTTPS | Polling |

## Adding Printers

### Method 1: IP Probe (Recommended for Docker)

The IP Probe feature allows you to detect printers by their IP address without network scanning (which doesn't work from Docker containers).

1. Navigate to **Admin → Printers**
2. Scroll to the **Find Printer by IP** section
3. Enter the printer's IP address
4. Click **Probe**

The system will:
- Check common printer ports (8883, 80, 443, 7125, 5000)
- Auto-detect the printer brand based on open ports
- Suggest a default name
- Check if the printer is already registered

If found, click **Add This Printer** to register it.

### Method 2: Network Scan

> **Note:** Network scanning (SSDP/mDNS) works best when running FilaOps directly on your host machine. It may not detect printers when running in Docker due to network isolation.

1. Click **Scan Network** in the header
2. Wait for discovery to complete (5-10 seconds)
3. Click **Add** next to any discovered printers

### Method 3: Manual Entry

1. Click **Add Printer** in the header
2. Fill in the required fields:
   - **Name**: Friendly name (e.g., "Leonardo", "Print Farm 1")
   - **Brand**: Select from dropdown
   - **IP Address**: Required for connection testing
3. Optional fields:
   - **Serial Number**: For identification and Pro features
   - **Access Code**: For authenticated connections (BambuLab)
   - **Model**: Specific printer model
   - **Location**: Physical location reference
4. Click **Create**

## Printer Configuration

### Required Fields

| Field | Purpose |
|-------|---------|
| Name | Display name in FilaOps |
| Brand | Determines connection protocol |
| IP Address | Required for connection testing and status |

### Optional Fields

| Field | Purpose |
|-------|---------|
| Serial Number | Unique identifier, needed for BambuLab MQTT |
| Access Code | Authentication for BambuLab printers |
| Model | Tracks specific printer model |
| Location | Reference to physical location |
| Work Center | Links printer to manufacturing work center |

### Work Center Assignment

Assigning a printer to a Work Center enables:
- **Active Work Display**: Shows current/queued production orders on the printer card
- **Scheduling Integration**: Production orders scheduled to the work center appear on assigned printers
- **Capacity Planning**: Track which printers are busy vs available

To assign:
1. Create a Work Center in **Admin → Work Centers** (if not already done)
2. Edit the printer
3. Select the Work Center from the dropdown
4. Save changes

## Connection Testing

### Test Individual Printer

Click the **Test** button on any printer card to verify connectivity. Results:
- **Green checkmark**: Printer is reachable
- **Red X**: Connection failed (check IP address and network)

### Test All Printers

Click **Test All** in the header to test all printers simultaneously.

### What Connection Test Checks

The connection test verifies **network reachability only**:
- For BambuLab: Checks if port 8883 (MQTT) is open
- For Klipper: Checks if port 7125 (Moonraker) responds
- For OctoPrint: Checks if port 5000 responds
- For others: Checks HTTP/HTTPS ports

> **Note:** The connection test does NOT verify authentication. A printer may show as "reachable" even if the access code is incorrect. Full authentication is verified when using Pro features like live status and camera feeds.

## Active Work Display

When a printer is assigned to a Work Center, the printer card shows:

- **Running**: Currently executing a production order operation
- **Queued**: Has operations waiting to start
- **Production Order**: The MO/WO code being worked
- **Product**: What's being manufactured
- **Progress**: Quantity completed vs ordered
- **Queue Depth**: How many operations are waiting

This updates automatically every 30 seconds.

## Status Indicators

| Status | Meaning |
|--------|---------|
| 🟢 Online | Printer is reachable and ready |
| 🟡 Idle | Printer is reachable, not printing |
| 🔴 Offline | Cannot reach printer |
| ⚪ Unknown | Status not yet checked |

## Community vs Pro Features

### Community (Free)

- Manual printer registration
- IP Probe discovery
- Network scan (limited in Docker)
- Connection testing (port check)
- Active work display (schedule-based)
- Work center assignment

### Pro (Future)

- Live printer status via MQTT/API
- Real-time print progress
- Camera feed integration
- Automatic status sync
- Print job history from printer
- Remote print control

## Troubleshooting

### Printer Not Found During Network Scan

1. Ensure printer is on the same network as FilaOps server
2. If running in Docker, use **IP Probe** instead
3. Check that printer's network features are enabled
4. Try rebooting the printer

### Connection Test Fails

1. Verify the IP address is correct
2. Ping the printer from the FilaOps server
3. Check firewall rules allow the required ports
4. Ensure printer is powered on and connected to network

### Active Work Not Showing

1. Verify printer is assigned to a Work Center
2. Check that Production Orders are scheduled to that Work Center
3. Ensure operations have status "running" or "queued"
4. Wait up to 30 seconds for the display to refresh

### BambuLab-Specific

For BambuLab printers, find your access code and serial number:
1. On the printer's touchscreen, go to **Settings → Network → Access Code**
2. Serial number is on the printer label or in **Settings → About**

These are optional for basic features but required for Pro MQTT integration.
