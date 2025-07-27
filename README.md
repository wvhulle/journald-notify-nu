# Journald Desktop Notifications

Nushell package for converting systemd journal entries to desktop notifications.

## Installation

```nushell
use ~/Code/journald-notify-nu
```

## Usage

```nushell
# Start monitoring (default: priorities 0-3)
journald-notify-nu

# Custom threshold
start-monitoring 4

# Test notifications
test-notification
```

## Priority Levels

Systemd priorities 0-7 (default monitors 0-3):
- 0: Emergency → Critical notification
- 1: Alert → Critical notification  
- 2: Critical → Critical notification
- 3: Error → Normal notification
- 4: Warning → Normal notification
- 5+: Notice/Info/Debug → Low priority notification

## Requirements

- Nushell, `journalctl`, `notify-send`
- Permission to read systemd journal