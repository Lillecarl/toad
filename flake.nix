{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
  inputs.pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    {
      packages = lib.genAttrs systems (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          package = (import ./. { inherit pkgs; }).package;
        in
        {
          default = package;
          toad = package;
          toad-claude = package.withPackages (
            with pkgs;
            [
              claude-code
              claude-agent-acp
            ]
          );
          toad-gemini = package.withPackages (
            with pkgs;
            [
              gemini-cli
            ]
          );
          toad-codex = package.withPackages (
            with pkgs;
            [
              codex
              codex-acp
            ]
          );
          toad-mistral = package.withPackages (
            with pkgs;
            [
              mistral-vibe
            ]
          );
        }
      );
    };
}
