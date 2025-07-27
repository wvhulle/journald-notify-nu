{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.journald-notify-nu;
in
{
  options.services.journald-notify-nu = {
    enable = mkEnableOption "journald desktop notifications service";

    package = mkPackageOption pkgs "journald-notify-nu" { };

    maxPriority = mkOption {
      type = types.int;
      default = 3;
      description = ''
        Maximum systemd priority level to notify for.
        Lower numbers are more important (0=Emergency, 1=Alert, 2=Critical, 3=Error, 4=Warning, etc.)
      '';
    };

    user = mkOption {
      type = types.str;
      default = "user";
      description = ''
        The user to run the service as. This should be the desktop user who will receive notifications.
      '';
    };

    restartSec = mkOption {
      type = types.str;
      default = "5s";
      description = ''
        Time to wait before restarting the service if it fails.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Ensure required packages are available
    environment.systemPackages = with pkgs; [
      cfg.package
      libnotify
    ];

    # Enable the user service for the specified user
    systemd.user.services.journald-notify-nu = {
      description = "Send journald errors to desktop notifications";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      serviceConfig = {
        ExecStart = if cfg.maxPriority == 3 then
          "${cfg.package}/bin/journald-notify-nu"
        else
          "${cfg.package}/bin/journald-notify-monitor ${toString cfg.maxPriority}";
        
        Restart = "always";
        RestartSec = cfg.restartSec;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Add session variable for easy service management
    environment.sessionVariables = {
      JOURNALD_NOTIFIER_SERVICE = "journald-notify-nu.service";
    };
  };
}