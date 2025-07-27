# Journald Desktop Notifications

A nushell package for converting systemd journal entries to desktop notifications.

## Features

- Monitor systemd journal in real-time
- Send desktop notifications for important log entries
- Configurable priority thresholds
- Icon detection from desktop files
- Error handling and graceful failures
- User unit filtering

## Installation

1. Clone or download this package
2. Add the package directory to your nushell modules path
3. Import the module in your config

```nushell
# Add to your config.nu
use ~/Code/journald-notify-nu
```

## Usage

### Start monitoring with default settings
```nushell
journald-notify-nu
```

### Start monitoring with custom priority threshold
```nushell
start-monitoring 4  # Monitor priority levels 0-4
```

### Test the notification system
```nushell
test-notification
```

### Use individual functions
```nushell
# Convert priority levels
journalctl-prio-to-notify-prio 2  # Returns "critical"

# Get icon for an application
get-icon-from-unit "firefox"  # Returns icon name
```

## Priority Levels

Systemd uses priority levels 0-7 (lower is more important):
- 0: Emergency
- 1: Alert  
- 2: Critical
- 3: Error
- 4: Warning
- 5: Notice
- 6: Informational
- 7: Debug

By default, only priorities 0-3 (Emergency through Error) trigger notifications.

## Requirements

- Nushell
- `journalctl` (systemd)
- `notify-send` (libnotify)
- Permission to read systemd journal

## Notes

This package monitors user systemd units and converts important log entries into desktop notifications. It's useful for staying informed about service failures, errors, and other important events without constantly checking logs.

The notification urgency is mapped as:
- Priority 0-2: Critical notifications
- Priority 3-4: Normal notifications  
- Priority 5+: Low priority notifications