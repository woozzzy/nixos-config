{ self, inputs, ... }: {
    flake.nixosModules.vscodium =
        {
            pkgs,
            lib,
            ...
        }:
        let
            user = "woozy";
            dots = "/home/${user}/nixos-config/dotfiles/vscode";

            # nixpkgs is still on VSCodium 1.126; the hybrid Markdown editor landed
            # upstream in 1.131. Flip this to false once nixpkgs catches up and
            # delete the `vscodiumLatest` block below.
            useLatestVscodium = true;

            vscodiumLatest = pkgs.buildVscode {
                pname = "vscodium";
                version = "1.135.06055";
                vscodeVersion = "1.135.0"; # gates asar patching in generic.nix — must be accurate
                executableName = "codium";
                longName = "VSCodium";
                shortName = "vscodium";
                sourceRoot = ".";
                commandLineArgs = "";
                updateScript = null;
                tests = { };
                meta = pkgs.vscodium.meta;
                src = pkgs.fetchurl {
                    url = "https://github.com/VSCodium/vscodium/releases/download/1.135.06055/VSCodium-linux-x64-1.135.06055.tar.gz";
                    hash = "sha256-wJ2KyN1/UrCe4VnuJLRAVB39j5N6D2+IzEKMeOSO4fI=";
                };
            };

            base = if useLatestVscodium then vscodiumLatest else pkgs.vscodium;

            codium = pkgs.vscode-with-extensions.override {
                vscode = base;
                vscodeExtensions = with pkgs.vscode-extensions; [
                    jnoortheen.nix-ide
                    sumneko.lua
                    mkhl.direnv
                    yzhang.markdown-all-in-one
                    editorconfig.editorconfig
                    asvetliakov.vscode-neovim
                ];
            };
        in
        {
            environment.systemPackages = [
                codium
                pkgs.stylua
            ];

            systemd.tmpfiles.rules = [
                "d /home/${user}/.config 0755 ${user} users - -"
                "d /home/${user}/.config/VSCodium 0755 ${user} users - -"
                "d /home/${user}/.config/VSCodium/User 0755 ${user} users - -"
                "L+ /home/${user}/.config/VSCodium/User/settings.json - - - - ${dots}/settings.json"
                "L+ /home/${user}/.config/VSCodium/User/keybindings.json - - - - ${dots}/keybindings.json"
            ];
        };
}
