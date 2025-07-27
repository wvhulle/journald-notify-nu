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
    let desktop_file_locations = [
        $"($nu.home-path)/.nix-profile/share/applications"
        "/run/current-system/sw/share/applications"
    ]

    mut icon = "error"

    for location in $desktop_file_locations {
        let desktop_file = $location | path join $"($app).desktop"
        if ($desktop_file | path exists) {
            try {
                $icon = open --raw $desktop_file 
                    | lines 
                    | find 'Icon=' 
                    | first 
                    | str replace 'Icon=' ''
                break
            } catch {
                # Continue if desktop file can't be read
            }
        }
    }

    $icon
}

# Main function - monitor systemd journal and send notifications
export def main [] {
    print "Starting journald desktop notifications monitor..."
    print $"Monitoring journal entries with priority <= ($MAX_SYSTEMD_PRIO)"
    
    try {
        journalctl --follow --priority=7 --output=json 
        | from json --objects 
        | each {|entry|
            try {
                let journalctl_prio = $entry | get PRIORITY | into int

                if $journalctl_prio <= $MAX_SYSTEMD_PRIO {
                    let notify_prio = journalctl-prio-to-notify-prio $journalctl_prio

                    let message: string = $entry 
                        | get MESSAGE 
                        | str replace --regex '^.*\.service: ' ''

                    if ('_SYSTEMD_USER_UNIT' in $entry) {
                        let app: string = $entry 
                            | get '_SYSTEMD_USER_UNIT' 
                            | str replace --regex '@.*\.service$' "" 
                            | str replace 'app-' ''

                        let icon = get-icon-from-unit $app

                        let args = [
                            --urgency=($notify_prio) 
                            --app-name=($app) 
                            --icon=($icon) 
                            ($message)
                        ]

                        try {
                            notify-send ...($args) | ignore
                        } catch {
                            print $"Failed to send notification for ($app): ($message)"
                        }
                    }
                }
            } catch {
                # Skip malformed journal entries
            }
        } | ignore
    } catch {
        print "Error: Failed to connect to systemd journal"
        print "Make sure you have permission to read the journal"
    }
}

# Start monitoring with custom priority threshold
export def start-monitoring [
    max_priority: int = 3  # Maximum priority level to notify for
] {
    print $"Starting monitoring with max priority: ($max_priority)"
    
    try {
        journalctl --follow --priority=7 --output=json 
        | from json --objects 
        | each {|entry|
            try {
                let journalctl_prio = $entry | get PRIORITY | into int

                if $journalctl_prio <= $max_priority {
                    let notify_prio = journalctl-prio-to-notify-prio $journalctl_prio

                    let message: string = $entry 
                        | get MESSAGE 
                        | str replace --regex '^.*\.service: ' ''

                    if ('_SYSTEMD_USER_UNIT' in $entry) {
                        let app: string = $entry 
                            | get '_SYSTEMD_USER_UNIT' 
                            | str replace --regex '@.*\.service$' "" 
                            | str replace 'app-' ''

                        let icon = get-icon-from-unit $app

                        let args = [
                            --urgency=($notify_prio) 
                            --app-name=($app) 
                            --icon=($icon) 
                            ($message)
                        ]

                        try {
                            notify-send ...($args) | ignore
                        } catch {
                            print $"Failed to send notification for ($app): ($message)"
                        }
                    }
                }
            } catch {
                # Skip malformed journal entries
            }
        } | ignore
    } catch {
        print "Error: Failed to connect to systemd journal"
    }
}

# Test the notification system
export def test-notification [] {
    print "Testing notification system..."
    
    try {
        notify-send --urgency=normal --app-name="journald-notify-nu" --icon="info" "Test notification from journald-notify-nu"
        print "Test notification sent successfully"
    } catch {
        print "Error: Failed to send test notification"
        print "Make sure notify-send is available in your PATH"
    }
}