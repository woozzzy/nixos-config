{ self, inputs, ... }: {
    flake.nixosModules.hyprland = { pkgs, lib, ... }: {
        programs.hyprland = {
            enable = true;
            xwayland.enable = true; # [default] X11 apps (some games, launchers) run under XWayland
        };

        environment.sessionVariables.NIXOS_OZONE_WL = "1";

        environment.systemPackages = with pkgs; [
            wl-clipboard # wl-copy / wl-paste — clipboard for the terminal and nvim (Useful utilities → Clipboard)
        ];

        # Not needed here, provided elsewhere:
        #   notification daemon, polkit agent, lock/idle, wallpaper → Noctalia (features/noctalia.nix)
        #   pipewire + wireplumber                                → core.nix (and graphical-desktop)
        #   xdg-desktop-portal-hyprland                           → this module
        #   fonts → default packages via graphical-desktop; add a Nerd Font in core.nix for icon glyphs
    };
}
