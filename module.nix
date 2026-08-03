{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.torrserver;
in
{
  options.services.torrserver = {
    enable = mkEnableOption "TorrServer stream service";

    enableGst = mkOption {
      type = types.bool;
      default = true;
      description = "Использовать сборку с GStreamer (для HLS-стриминга и транскодинга).";
    };

    package = mkOption {
      type = types.package;
      default =
        if cfg.enableGst then
          pkgs.callPackage ./package.nix { withGst = true; }
        else
          pkgs.callPackage ./package.nix { withGst = false; };
      defaultText = literalExpression "if cfg.enableGst then pkgs.torrserver-gst else pkgs.torrserver";
      description = "Пакет TorrServer.";
    };

    port = mkOption {
      type = types.port;
      default = 8090;
      description = "HTTP порт сервера (--port).";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "";
      description = "IP адрес привязки (--ip). Пустое значение слушат все интерфейсы.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/torrserver";
      description = "Путь к базе данных и конфигурациям (--path).";
    };

    readOnlyDb = mkOption {
      type = types.bool;
      default = false;
      description = "Запуск БД в режиме только для чтения (--rdb).";
    };

    httpAuth = mkOption {
      type = types.bool;
      default = false;
      description = "Включить авторизацию на все запросы (--httpauth).";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Автоматически открыть порт в фаерволе.";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--webdav"
        "--maxsize"
        "10737418240"
      ];
      description = "Дополнительные аргументы запуска.";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    users.users.torrserver = {
      isSystemUser = true;
      group = "torrserver";
      description = "TorrServer daemon user";
    };
    users.groups.torrserver = { };

    systemd.services.torrserver = {
      description = "TorrServer Torrent Streaming Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "torrserver";
        Group = "torrserver";

        StateDirectory = "torrserver";
        WorkingDirectory = "/var/lib/torrserver";

        ExecStart =
          let
            args = [
              "--port"
              (toString cfg.port)
              "--path"
              "/var/lib/torrserver"
            ]
            ++ optionals (cfg.bindAddress != "") [
              "--ip"
              cfg.bindAddress
            ]
            ++ optionals cfg.readOnlyDb [ "--rdb" ]
            ++ optionals cfg.httpAuth [ "--httpauth" ]
            ++ cfg.extraFlags;
          in
          "${cfg.package}/bin/TorrServer ${concatStringsSep " " args}";

        Restart = "on-failure";
        RestartSec = 5;

        ProtectSystem = "full";
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };
  };
}
