{ self, inputs, ... }: {
    flake.nixosModules.theme = { lib, pkgs, ... }: {
        environment.systemPackages = with pkgs; [
            apple-cursor # XCursor theme "macOS" (marked unfree in nixpkgs; allowUnfree is already on in core)
            whitesur-icon-theme # "WhiteSur", "WhiteSur-dark", "WhiteSur-light"
        ];
        # GTK apps and Noctalia read these from GSettings. Method: wiki.hypr.land/Nix/Advanced/ → themes.
        programs.dconf.profiles.user.databases = [
            {
                settings."org/gnome/desktop/interface" = {
                    icon-theme = "WhiteSur-dark";
                    cursor-theme = "macOS";
                    cursor-size = lib.gvariant.mkInt32 24;
                };
            }
        ];
    };
}
