# Monitoring module for Kydra OS systems
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.kydra.monitoring;
in

{
  options.kydra.monitoring = {
    enable = mkEnableOption "Kydra monitoring services";

    prometheusPort = mkOption {
      type = types.port;
      default = 9090;
      description = "Port for Prometheus to listen on";
    };

    grafanaPort = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for Grafana to listen on";
    };

    nodeExporterPort = mkOption {
      type = types.port;
      default = 9100;
      description = "Port for Node Exporter to listen on";
    };
  };

  config = mkIf cfg.enable {
    # Prometheus node exporter
    services.prometheus.exporters.node = {
      enable = true;
      port = cfg.nodeExporterPort;
      enabledCollectors = [
        "systemd"
        "processes"
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "netstat"
      ];
    };

    # Prometheus server (only on designated monitoring node)
    services.prometheus = mkIf (config.networking.hostName == "nas") {
      enable = true;
      port = cfg.prometheusPort;
      
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "desktop:${toString cfg.nodeExporterPort}"
                "nas:${toString cfg.nodeExporterPort}"
                "router:${toString cfg.nodeExporterPort}"
              ];
            }
          ];
        }
      ];
    };

    # Grafana (only on designated monitoring node)
    services.grafana = mkIf (config.networking.hostName == "nas") {
      enable = true;
      settings = {
        server = {
          http_port = cfg.grafanaPort;
          http_addr = "0.0.0.0";
        };
        security = {
          admin_user = "kydra";
          admin_password = "$__file{/var/lib/grafana/admin_password}";
        };
      };
    };

    # Firewall rules
    networking.firewall.allowedTCPPorts = mkMerge [
      [ cfg.nodeExporterPort ]
      (mkIf (config.networking.hostName == "nas") [ cfg.prometheusPort cfg.grafanaPort ])
    ];
  };
}