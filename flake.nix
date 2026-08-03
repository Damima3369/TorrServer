{
  description = "Nix Flake for TorrServer (Standard & GST builds)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          torrserver = pkgs.callPackage ./package.nix { withGst = false; };
          torrserver-gst = pkgs.callPackage ./package.nix { withGst = true; };
          default = self.packages.${system}.torrserver-gst;
        }
      );

      overlays.default = final: prev: {
        torrserver = self.packages.${final.system}.torrserver;
        torrserver-gst = self.packages.${final.system}.torrserver-gst;
      };

      nixosModules.default = import ./module.nix;
    };
}
