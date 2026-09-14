{ self, inputs, ... }: {
    flake.nixosModules.core = { pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;
        networking.networkmanager.enable = true;
        time.timeZone = "America/New_York";

        programs.nix-ld.enable = true;

        # System Packages
        environment.systemPackages = with pkgs; [
            wget
            curl
            kitty
            sbctl
            btop
            fastfetch
            eza
            bat
            yazi
            tmux
            inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
            obsidian
            sbctl
        ];

        # Audio
        security.rtkit.enable = true;
        services.pipewire = {
            enable = true;
            alsa.enable = true;
            pulse.enable = true;
        };

        # GTK 4 Darkmode
        programs.dconf = {
            enable = true;
            profiles.user.databases = [
                {
                    settings."org/gnome/desktop/interface" = {
                        color-scheme = "prefer-dark";
                        gtk-theme = "Adwaita-dark";
                    };
                }
            ];
        };

        # GTK 3 Darkmode
        environment.sessionVariables.GTK_THEME = "Adwaita:dark";

        # QT Darkmode
        qt = {
            enable = true;
            platformTheme = "gnome";
            style = "adwaita-dark";
        };

        # User
        users.users.woozy = {
            isNormalUser = true;
            extraGroups = [
                "wheel"
                "networkmanager"
                "video"
                "audio"
            ];
        };
    };
}
