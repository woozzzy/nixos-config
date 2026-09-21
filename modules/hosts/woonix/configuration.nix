{ self, inputs, ... }: {
  flake.nixosModules.woonixConfiguration = { pkgs, lib, ... }: {
    imports = [
      self.nixosModules.woonixHardware
      self.nixosModules.core
      self.nixosModules.fonts
      self.nixosModules.nvidia
      self.nixosModules.cuda
      self.nixosModules.hyprland
      self.nixosModules.jail
      self.nixosModules.theme
      self.nixosModules.noctalia
      self.nixosModules.git
      self.nixosModules.neovim
      self.nixosModules.zsh
      self.nixosModules.vscodium
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    networking.hostName = "woonix";
    boot.loader = {
      efi.canTouchEfiVariables = true;
      limine = {
        enable = true;
        maxGenerations = 5;
        enrollConfig = true;
        panicOnChecksumMismatch = true;

        extraEntries = ''
          /Windows 11
              protocol: efi_chainload
              image_path: uuid(c503124f-c625-4974-a02a-10edecdd72ae):/EFI/Microsoft/Boot/bootmgfw.efi
        '';
      };
      timeout = 15;
    };

    console = {
      earlySetup = true;
      packages = [ pkgs.terminus_font ];
      font = "ter-v32n";
    };

    system.stateVersion = "26.05";
  };
}
