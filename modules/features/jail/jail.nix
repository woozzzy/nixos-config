{ self, inputs, ... }: {
  flake.nixosModules.jail =
    { pkgs, ... }:
    let
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
        agents.hermes-agent
        agents.oh-my-pi
        agents.pi-coding-agent
        agents.prime-agent
      ];

      # .jail/ is never committed, from any repo, from either side of the wall.
      programs.git.config.core.excludesFile = "${pkgs.writeText "gitignore-global" ".jail/\n"}";
    };
}
