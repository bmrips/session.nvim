{
  description = "Session plugin for Neovim";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    pre-commit.url = "github:cachix/git-hooks.nix";
    pre-commit.inputs.nixpkgs.follows = "nixpkgs";
    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {

      imports = with inputs; [
        pre-commit.flakeModule
        treefmt.flakeModule
      ];

      systems = [ "x86_64-linux" ];

      perSystem =
        { config, pkgs, ... }:
        {
          devShells.default = config.pre-commit.devShell;
          pre-commit.settings = {
            package = pkgs.prek;
            hooks = {
              actionlint.enable = true;
              check-added-large-files.enable = true;
              check-merge-conflicts.enable = true;
              check-symlinks.enable = true;
              check-toml.enable = true;
              check-vcs-permalinks.enable = true;
              check-yaml.enable = true;
              convco.enable = true;
              deadnix.enable = true;
              detect-private-keys.enable = true;
              markdownlint.enable = true;
              mixed-line-endings.enable = true;
              selene.enable = true;
              statix.enable = true;
              statix.settings.format = "stderr";
              treefmt.enable = true;
              trim-trailing-whitespace.enable = true;
              typos.enable = true;
            };
          };
          treefmt.programs = {
            mdformat = {
              enable = true;
              settings.wrap = "no";
            };
            nixf-diagnose = {
              enable = true;
              ignore = [ "sema-primop-overridden" ];
            };
            nixfmt.enable = true;
            stylua = {
              enable = true;
              settings = {
                call_parentheses = "None";
                column_width = 100;
                indent_type = "Spaces";
                indent_width = 2;
                quote_style = "AutoPreferSingle";
              };
            };
            yamlfmt.enable = true;
          };
        };

    };
}
