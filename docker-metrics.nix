{ config, pkgs, ... }:
let
  metricsPort = 9323;
in
{
  virtualisation.docker = {
    enable = true;
    liveRestore = false;
    enableOnBoot = true;
    autoPrune.enable = true;
    extraOptions = ''--metrics-addr=172.17.0.1:${toString metricsPort} --experimental'';
  };

  networking.firewall = {
    interfaces = {
      "docker_gwbridge".allowedTCPPorts = [ metricsPort ];
    };
    enable = true;
  };
}
