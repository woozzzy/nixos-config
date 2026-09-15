{ self, inputs, ... }: {
  flake.nixosModules.neovim = { pkgs, ... }: {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    environment.systemPackages = with pkgs; [
      gcc
      gnumake
      unzip
      ripgrep
      fd
      nodejs
      lua-language-server
      nixfmt
      nixd
    ];
  };
}
