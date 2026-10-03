{
  description = "CollBox's Nix packages for third-party dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # Consumers who want these packages merged into their own `pkgs`
      # (and built against their own nixpkgs) use the overlay; everyone
      # else can take `packages.${system}.<name>` directly.
      overlays.default =
        final: prev:
        import ./pkgs {
          inherit lib;
          inherit (final) callPackage;
        };

      packages = forAllSystems (
        pkgs:
        # Only expose what actually builds on this platform, so that
        # `nix flake check` and `nix flake show` stay green everywhere.
        lib.filterAttrs (_: drv: lib.meta.availableOn pkgs.stdenv.hostPlatform drv) (
          import ./pkgs {
            inherit lib;
            inherit (pkgs) callPackage;
          }
        )
      );

      checks = forAllSystems (pkgs: self.packages.${pkgs.stdenv.hostPlatform.system});

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nix-update
            nixfmt
          ];
        };
      });
    };
}
