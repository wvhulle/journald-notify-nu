# sysnotify

Desktop notifications for systemd service failures.

Install:
```bash
git clone https://github.com/wvhulle/sysnotify ~/.config/nushell/modules/sysnotify
echo "use ~/.config/nushell/modules/sysnotify" >> ~/.config/nushell/config.nu
```

Test without installing:
```bash
nu -c "source sysnotify.nu; test"
```

Usage:
```nushell
sysnotify          # Monitor failures (priority ≤3)
sysnotify -p 4     # Custom priority threshold
sysnotify test     # Test notifications
```

Requires `journalctl` and `notify-send`.