{ self, inputs, ... }: {
    flake.nixosModules.zsh =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        {

            # ---------- zsh ----------
            programs.zsh = {
                enable = true;
                enableCompletion = true;
                autosuggestions.enable = true; # ghost-text suggestions from history
                syntaxHighlighting.enable = true; # red = bad command, green = good
                histSize = 50000;
                setOptions = [
                    "HIST_IGNORE_ALL_DUPS"
                    "HIST_IGNORE_SPACE"
                    "HIST_REDUCE_BLANKS"
                    "SHARE_HISTORY"
                    "INC_APPEND_HISTORY"
                    "HIST_FCNTL_LOCK"
                    "AUTO_CD"
                    "AUTO_PUSHD"
                    "PUSHD_IGNORE_DUPS"
                    "INTERACTIVE_COMMENTS"
                    "NO_BEEP"
                ];
                promptInit = ""; # disable NixOS's default `prompt walters`; starship owns the prompt

                interactiveShellInit = ''
                    # completion: case-insensitive, menu-select, colored
                    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
                    zstyle ':completion:*' menu select
                    zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
                    zmodload zsh/complist

                    # keybindings
                    bindkey -e
                    bindkey '^[[A' history-search-backward   # up/down: prefix history search
                    bindkey '^[[B' history-search-forward
                    bindkey '^ '   autosuggest-accept        # ctrl+space accepts suggestion
                    bindkey '^[[1;5C' forward-word           # ctrl+right / ctrl+left
                    bindkey '^[[1;5D' backward-word
                '';

                shellAliases =
                    let
                        flake = "/home/woozy/nixos-config#${config.networking.hostName}";
                    in
                    {
                        # nixos-config workflow (§6)
                        nrs = "git -C ~/nixos-config add -A && sudo nixos-rebuild switch --flake ${flake}";
                        nrb = "git -C ~/nixos-config add -A && sudo nixos-rebuild boot --flake ${flake}";
                        ndb = "git -C ~/nixos-config add -A && nixos-rebuild dry-build --flake ${flake}";
                        nfc = "nix flake check ~/nixos-config";
                        nfu = "nix flake update --flake ~/nixos-config";
                        ngc = "sudo nix-collect-garbage -d";
                        nsp = "nix search nixpkgs";
                        nsh = "nix-shell -p";
                        ndev = "nix develop";

                        # modern replacements
                        ls = "eza --icons --group-directories-first";
                        ll = "eza -l --icons --git --group-directories-first";
                        la = "eza -la --icons --git --group-directories-first";
                        lt = "eza --tree --level=2 --icons";
                        cat = "bat --paging=never";
                        grep = "rg";
                        find = "fd";

                        # misc
                        v = "nvim";
                        g = "git";
                        gs = "git status -sb";
                        gd = "git diff";
                        gl = "git log --oneline --graph --decorate -20";
                        ".." = "cd ..";
                        "..." = "cd ../..";
                        gpu = "nvidia-smi";
                    };
            };

            users.defaultUserShell = pkgs.zsh; # avoids touching the user block in core.nix
            environment.pathsToLink = [ "/share/zsh" ]; # expose completions shipped by packages

            # ---------- prompt ----------
            programs.starship.enable = true;

            # ---------- QoL tools (NixOS modules handle shell wiring) ----------
            programs.fzf = {
                fuzzyCompletion = true;
                keybindings = true;
            }; # ctrl+r / ctrl+t / alt+c
            programs.zoxide.enable = true; # `z <dir>` smart cd
            programs.direnv = {
                enable = true;
                nix-direnv.enable = true;
            }; # auto `nix develop` per project

            environment.systemPackages = with pkgs; [
                eza
                bat
                fd
                ripgrep
            ];

            # starship/eza icons need a Nerd Font; drop this line if core/noctalia already ships one
        };
}
