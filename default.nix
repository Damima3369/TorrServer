{
  pkgs ? import <nixpkgs> { },
}:

rec {
  torrserver = pkgs.callPackage ./package.nix { withGst = false; };
  torrserver-gst = pkgs.callPackage ./package.nix { withGst = true; };
  default = torrserver-gst;
}
