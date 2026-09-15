{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.scrolloverview = pkgs.hyprlandPlugins.mkHyprlandPlugin {
      pluginName = "scrolloverview";
      version = inputs.hyprland-scroll-overview.shortRev or "unknown";
      src = inputs.hyprland-scroll-overview;
      buildInputs = [ pkgs.lua5_4 ];
      enableParallelBuilding = true;
      dontUseCmakeConfigure = true;
      buildPhase = ''
        runHook preBuild
        export SCROLLOVERVIEW_BUILD_VERSION="${inputs.hyprland-scroll-overview.shortRev or "unknown"}"
        make all
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/lib"
        mv scrolloverview.so "$out/lib/libscrolloverview.so"
        runHook postInstall
      '';
      meta.license = pkgs.lib.licenses.bsd3;
    };
  };

  flake.nixosModules.hyprland = { pkgs, lib, ... }: {

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      wl-clipboard
    ];
    environment.etc."hypr/plugins/libscrolloverview.so".source = "${
      self.packages.${pkgs.stdenv.hostPlatform.system}.scrolloverview
    }/lib/libscrolloverview.so";
  };
}
