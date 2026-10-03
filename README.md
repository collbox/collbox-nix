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

## Building and CI

There is no binary cache: consumers build each package from source the
first time they use it, and Nix keeps the result in their store after
that.  Everything here is small enough for that to be fine; if a
package ever gets slow to build, that's the time to add a cache.

CI (`.github/workflows/ci.yml`) runs `nix flake check` on
x86_64-linux, aarch64-linux and aarch64-darwin for every push to
`master` and every pull request, building every package natively on
each, and fails if `nix fmt` would change anything.

Locally, `nix flake check` builds only for your own system.  Adding
`--all-systems` fails on packages for other platforms, since they
can't be built here; `nix flake check --all-systems --no-build`
evaluates them without building, and CI covers the rest.

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
