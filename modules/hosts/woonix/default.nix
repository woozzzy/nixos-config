{ self, inputs, ... }: {
    flake.nixosConfigurations.woonix = inputs.nixpkgs.lib.nixosSystem {
        modules = [
            self.nixosModules.woonixConfiguration
        ];
    };
}
