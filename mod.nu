# Journald Desktop Notifications
# A nushell package for converting systemd journal entries to desktop notifications

# Lower is more important (see `man systemd.journal-fields`)
const MAX_SYSTEMD_PRIO: int = 3

# Convert journalctl priority to notify-send urgency level
export def journalctl-prio-to-notify-prio [
    journalctl_prio: int  # Systemd priority level (0-7)
] {
    if $journalctl_prio < 3 {
        "critical"
    } else if $journalctl_prio < 5 {
        "normal"
    } else {
        "low"
    }
}

# Get icon for application from desktop file
export def get-icon-from-unit [
    app: string  # Application/unit name
] {
    [
        ($nu.home-path | path join ".nix-profile/share/applications")       # NixOS user profile
        "/run/current-system/sw/share/applications"                        # NixOS system
        ($nu.home-path | path join ".local/share/applications")            # User applications
        "/usr/share/applications"                                          # System applications (Debian/Fedora/etc)
        "/usr/local/share/applications"                                    # Local system applications
        "/var/lib/flatpak/exports/share/applications"                      # Flatpak system
        ($nu.home-path | path join ".local/share/flatpak/exports/share/applications") # Flatpak user
        "/snap/bin"                                                        # Snap applications (Ubuntu)
    ]
    | each {|location| 
        $location | path join $"($app).desktop" 
    }
    | where {|file| $file | path exists }
    | each {|desktop_file|
        try {
            open --raw $desktop_file 
            | lines 
            | find 'Icon='
            | first
            | default ""
            | str replace 'Icon=' ''
        } catch {
            ""
        }
    }
    | where {|icon| $icon != "" }
    | get 0? 
    | default "error"
}

# Process a journal entry and send notification if needed
def process-journal-entry [
    entry: record,    # Journal entry from journalctl
    max_priority: int # Maximum priority level to notify for
] {
    try {
        # Skip entries without required fields
        if not ('PRIORITY' in $entry and 'MESSAGE' in $entry) {
            return
        }

        let journalctl_prio = ($entry | get PRIORITY | into int)

        if $journalctl_prio <= $max_priority {
            let notify_prio = (journalctl-prio-to-notify-prio $journalctl_prio)

            let message = ($entry 
                | get MESSAGE 
                | str replace --regex '^.*\.service: ' ''
                | str replace --all '\\"' '"'
                | str trim)

            # Only process user units for now
            if ('_SYSTEMD_USER_UNIT' in $entry) {
                let app = ($entry 
                    | get '_SYSTEMD_USER_UNIT' 
                    | str replace --regex '\.service$' "" 
                    | str replace --regex '@.*$' ""
                    | str replace 'app-' ''
                    | str trim)

                # Skip empty app names or messages
                if ($app | is-empty) or ($message | is-empty) {
                    return
                }

                let icon = (get-icon-from-unit $app)

                let args = [
                    --urgency=($notify_prio) 
                    --app-name=($app) 
                    --icon=($icon) 
                    ($message)
                ]

                try {
                    ^notify-send ...$args | ignore
                } catch { |err|
                    print $"Failed to send notification for ($app): ($err.msg)"
                }
            }
        }
    } catch { |err|
        # Skip malformed journal entries silently
    }
}

# Start monitoring with custom priority threshold
export def start-monitoring [
    max_priority: int = 3  # Maximum priority level to notify for
] {
    if $max_priority < 0 or $max_priority > 7 {
        error make {msg: "Priority must be between 0 and 7"}
    }

    print $"Starting journald desktop notifications monitor..."
    print $"Monitoring journal entries with priority <= ($max_priority)"
    
    try {
        ^journalctl --follow --priority=7 --output=json 
        | lines
        | where {|line| ($line | str trim | str length) > 0 }
        | each {|line| 
            try {
                let entry = ($line | from json)
                process-journal-entry $entry $max_priority
            } catch {
                # Skip malformed JSON lines silently
            }
        }
        | ignore
    } catch {
        print "Error: Failed to connect to systemd journal"
        print "Make sure you have permission to read the journal"
    }
}

# Main function - monitor systemd journal and send notifications
export def main [] {
    start-monitoring $MAX_SYSTEMD_PRIO
}

# Test the notification system
export def test-notification [] {
    print "Testing notification system..."
    
    try {
        ^notify-send --urgency=normal --app-name="journald-notify-nu" --icon="info" "Test notification from journald-notify-nu"
        print "Test notification sent successfully"
    } catch {
        print "Error: Failed to send test notification"
        print "Make sure notify-send is available in your PATH"
    }
}