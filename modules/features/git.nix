{ self, inputs, ... }: {
  flake.nixosModules.git = { pkgs, lib, ... }: {
    programs.git = {
      enable = true;
      lfs.enable = true;
      config = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        user = {
          name = "woozzzy";
          email = "sunwoo.park0203@gmail.com";
        };
      };
    };

    programs.ssh.startAgent = true;
  };
}
