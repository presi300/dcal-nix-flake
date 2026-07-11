{
  description = "Standalone flake to install dcal (Dank Calendar)";

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
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        Downs = pkgs.buildGoModule rec {
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
          dontWrapQtApps = true;
          proxyVendor = false;
          vendorHash = "sha256-2eBwE1jnvGDQiMD1wKDTIr2CnKWWdhNpIHhkl2R2jIQ=";

          # Keep nativeBuildInputs completely free of the Qt hook so the module fetch works
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

          postInstall = ''
            mkdir -p $out/share/quickshell/dankcal
            cp -r ../quickshell/* $out/share/quickshell/dankcal/

            mkdir -p $out/share/icons/hicolor/scalable/apps
            cp ../assets/dankcalendar.svg $out/share/icons/hicolor/scalable/apps/

            mkdir -p $out/share/applications
            cp ../assets/com.danklinux.dankcalendar.desktop $out/share/applications/
          '';

          # Manually invoke the Qt wrapper tool *only* on the final binary output
          postFixup = ''
            wrapProgram $out/bin/dcal \
              --prefix QT_PLUGIN_PATH : "${pkgs.qt6.qtbase}/${pkgs.qt6.qtbase.qtPluginPrefix}" \
              --prefix QML2_IMPORT_PATH : "${pkgs.qt6.qtdeclarative}/${pkgs.qt6.qtbase.qtQmlPrefix}:${pkgs.quickshell}/${pkgs.qt6.qtbase.qtQmlPrefix}" \
              --add-flags "-c $out/share/quickshell/dankcal"
          '';
        };
      in
      {
        packages.default = Downs;
        packages.dcal = Downs;
      }
    );
}
