{ self, inputs, ... }: {
  flake.nixosModules.jail =
    { pkgs, ... }:
    let
      agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

      jail = pkgs.writeShellApplication {
        name = "jail";
        runtimeInputs = with pkgs; [
          bubblewrap
          coreutils
          findutils
          git
        ];
        text = builtins.readFile ./jail.sh;
      };
    in
    {
      environment.systemPackages = with pkgs; [
        jail
        agents.claude-code
        agents.codex
        agents.omp
        agents.pi
        agents.hermes-agent
        agents.prime-agent
      ];

      programs.git.config.core.excludesFile = "${pkgs.writeText "gitignore-global" ".jail/\n"}";
    };
}
