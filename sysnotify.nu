# Journald Desktop Notifications
# A nushell package for converting systemd journal entries to desktop notifications

# Lower is more important (see `man systemd.journal-fields`)
const MAX_SYSTEMD_PRIO: int = 3

# Convert journalctl priority to notify-send urgency level
export def journalctl-prio-to-notify-prio [
    journalctl_prio: int  # Systemd priority level (0-7)
] {
    match $journalctl_prio {
        0..2 => "critical",
        3..4 => "normal",
        _ => "low"
    }
}

# Get icon for application from desktop file
export def get-icon-from-unit [
    app: string  # Application/unit name
] {
    let desktop_paths = [
        ($nu.home-path | path join ".nix-profile/share/applications")
        "/run/current-system/sw/share/applications"
        ($nu.home-path | path join ".local/share/applications")
        "/usr/share/applications"
        "/usr/local/share/applications"
        "/var/lib/flatpak/exports/share/applications"
        ($nu.home-path | path join ".local/share/flatpak/exports/share/applications")
        "/snap/bin"
    ]
    
    $desktop_paths
    | each {|path| $path | path join $"($app).desktop" }
    | where {|file| $file | path exists }
    | first?
    | if $in != null {
        try {
            open --raw $in
            | lines
            | where {|line| $line | str starts-with 'Icon=' }
            | first?
            | default ""
            | str replace 'Icon=' ''
        } catch {
            "error"
        }
    } else {
        "error"
    }
}

def process-journal-entry [
    entry: record,
    max_priority: int
] {
    if not ('PRIORITY' in $entry and 'MESSAGE' in $entry and '_SYSTEMD_USER_UNIT' in $entry) {
        return
    }

    let priority = $entry.PRIORITY | into int
    if $priority > $max_priority { return }

    let message = $entry.MESSAGE
        | str replace --regex '^.*\.service: ' ''
        | str replace --all '\\"' '"'
        | str trim

    let app = $entry._SYSTEMD_USER_UNIT
        | str replace --regex '\.service$' ""
        | str replace --regex '@.*$' ""
        | str replace 'app-' ''
        | str trim

    if ($app | is-empty) or ($message | is-empty) { return }

    let urgency = journalctl-prio-to-notify-prio $priority
    let icon = get-icon-from-unit $app

    try {
        ^notify-send --urgency=$urgency --app-name=$app --icon=$icon $message
    } catch { |err|
        print $"Failed to send notification for ($app): ($err.msg)"
    }
}

export def main [
    --priority(-p): int = 3  # Maximum priority level to notify for (0-7)
] {
    if $priority not-in 0..7 {
        error make {msg: "Priority must be between 0 and 7"}
    }

    print $"Starting journald desktop notifications monitor..."
    print $"Monitoring journal entries with priority <= ($priority)"
    
    try {
        ^journalctl --follow --priority=7 --output=json 
        | lines
        | where {|line| not ($line | str trim | is-empty) }
        | each {|line| 
            try {
                let entry = ($line | from json)
                process-journal-entry $entry $priority
            } catch {
                null
            }
        }
        | ignore
    } catch {
        error make {msg: "Failed to connect to systemd journal. Make sure you have permission to read the journal"}
    }
}

export def test [] {
    print "Testing notification system..."
    
    try {
        ^notify-send --urgency=normal --app-name="journald-notify-nu" --icon="info" "Test notification from journald-notify-nu"
        print "Test notification sent successfully"
    } catch {
        error make {msg: "Failed to send test notification. Make sure notify-send is available in your PATH"}
    }
}