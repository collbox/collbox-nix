# Every directory under pkgs/ containing a `package.nix` becomes a
# package of the same name, much like nixpkgs' `pkgs/by-name`.  Adding
# a package means adding a directory; nothing here needs editing.
#
# `lib` arrives separately from `callPackage` because, inside an
# overlay, the set of names must not depend on `final` -- deriving it
# from `final.lib` makes the overlay's own output an input to itself.
{ lib, callPackage }:

let
  dirs = lib.filterAttrs (
    name: type: type == "directory" && builtins.pathExists (./. + "/${name}/package.nix")
  ) (builtins.readDir ./.);
in
lib.mapAttrs (name: _: callPackage (./. + "/${name}/package.nix") { }) dirs
