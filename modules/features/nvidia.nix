{ self, inputs, ... }: {
    flake.nixosModules.nvidia = { config, ... }: {
        hardware.graphics.enable = true;
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia = {
            modesetting.enable = true;
            open = true;
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.stable;
            nvidiaPersistenced = true;
        };

        boot.extraModprobeConfig = ''
            options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1;PerfLevelSrc=0x2222;PowerMizerDefaultAC=0x1"
        '';
    };
}
