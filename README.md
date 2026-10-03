# collbox-nix

Nix packages for third-party dependencies CollBox needs that nixpkgs
lacks (or doesn't package the way we want).

## Layout

```
flake.nix              # outputs: packages, overlays.default, checks, formatter
pkgs/default.nix       # auto-discovers every pkgs/<name>/package.nix
pkgs/<name>/package.nix
```

## Adding a package

1. Create `pkgs/<name>/package.nix` as an ordinary `callPackage`-style
   function (`{ lib, stdenv, fetchurl, ... }: stdenv.mkDerivation { ... }`).
   Supporting files (patches, lockfiles) go alongside it.
2. Give it a `meta.platforms` if it doesn't build everywhere; packages
   unavailable on a system are hidden from that system's outputs.
3. `git add` it — flakes only see tracked files.
4. `nix build .#<name>`, then `nix flake check`.

`nix fmt` formats everything.  `nix develop` provides `nix-update`
for bumping versions (`nix-update --flake <name>`).

## Using from another project

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    collbox-nix = {
      url = "github:collbox/collbox-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, collbox-nix, ... }: {
    # Either take packages directly:
    #   collbox-nix.packages.${system}.<name>
    # or apply the overlay so they appear in `pkgs`:
    #   import nixpkgs { inherit system; overlays = [ collbox-nix.overlays.default ]; }
  };
}
```

While iterating locally, point the consumer at a checkout instead:
`nix develop --override-input collbox-nix path:../collbox-nix`.
