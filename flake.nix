{
  description = "Standalone flake to install and configure dcal (Dank Calendar)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
    }:
    # Keep the package definition multi-system
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        dcal-pkg = pkgs.buildGoModule rec {
          pname = "dankcalendar";
          version = "0.2.2";

          src = pkgs.fetchFromGitHub {
            owner = "AvengeMedia";
            repo = "dankcalendar";
            rev = "v${version}";
            hash = "sha256-7zVSQqLuHoEJITSoeDUwvfs9zb2zDZMiDDDnLE0ytuA=";
          };

          modRoot = "core";
          subPackages = [ "cmd/dcal" ];

          postPatch = ''
            rm -rf vendor
          '';

          proxyVendor = false;
          vendorHash = "sha256-2eBwE1jnvGDQiMD1wKDTIr2CnKWWdhNpIHhkl2R2jIQ=";

          nativeBuildInputs = [
            pkgs.go
            pkgs.makeWrapper
          ];
          buildInputs = [
            pkgs.libsecret
            pkgs.glib
            pkgs.qt6.qtbase
            pkgs.quickshell
            pkgs.qt6.qtdeclarative
          ];

          dontWrapQtApps = true;

          postInstall = ''
            mkdir -p $out/share/quickshell/dankcal
            cp -r ../quickshell/* $out/share/quickshell/dankcal/

            mkdir -p $out/share/icons/hicolor/scalable/apps
            cp ../assets/dankcalendar.svg $out/share/icons/hicolor/scalable/apps/

            mkdir -p $out/share/applications
            cp ../assets/com.danklinux.dankcalendar.desktop $out/share/applications/

          '';

          postFixup = ''
            wrapProgram $out/bin/dcal \
              --prefix QT_PLUGIN_PATH : "${pkgs.qt6.qtbase}/${pkgs.qt6.qtbase.qtPluginPrefix}" \
              --prefix QML2_IMPORT_PATH : "${pkgs.qt6.qtdeclarative}/${pkgs.qt6.qtbase.qtQmlPrefix}:${pkgs.quickshell}/${pkgs.qt6.qtbase.qtQmlPrefix}" \
              --add-flags "-c $out/share/quickshell/dankcal"
          '';
        };
      in
      {
        packages.default = dcal-pkg;
        packages.dcal = dcal-pkg;
      }
    ))
    // {
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.dcal;
          dcalPkg = self.packages.${pkgs.system}.default;
        in
        {
          options.services.dcal = {
            enable = lib.mkEnableOption "Dank Calendar daemon and shell UI";
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ dcalPkg ];

            # Define the pristine user service entirely within Nix
            systemd.user.services.dcal = {
              description = "Dank Calendar Daemon";
              after = [ "graphical-session.target" ];
              wantedBy = [ "graphical-session.target" ];

              serviceConfig = {
                # Points directly to the wrapped store binary
                # Type = "forking";
                ExecStart = "${dcalPkg}/bin/dcal daemon";
                Restart = "on-failure";
                RestartSec = 3;
              };
            };
          };
        };
    };
}
