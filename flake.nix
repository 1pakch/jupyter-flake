{
  description = "A flake with Jupyter package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    scanpy-env.url = "github:1pakch/scanpy-nix-flake/kernel";
  };

  outputs = { self, nixpkgs, scanpy-env }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    ks-utils = import ./kernelspec-utils.nix;
    kernelspecs = {

      pykernel = ks-utils.fromPythonEnv {
        env = scanpy-env.packages.x86_64-linux.default;
        suffix = "(scanpy)";
      };

      r-single-cell = ks-utils.fromREnv {
        env = pkgs.rWrapper.override {
          packages = [
            pkgs.rPackages.IRkernel
            pkgs.rPackages.SoupX
            pkgs.rPackages.scDblFinder
          ];
        };
        suffix = "(SoupX+scDblFinder)";
      };

      r-mofa2 = ks-utils.fromREnv {
        env = pkgs.rWrapper.override {
          packages = [
            pkgs.rPackages.IRkernel
            pkgs.rPackages.MOFA2
            pkgs.rPackages.tidyverse
          ];
        };
        suffix = "(MOFA2)";
      };

    };

  in {

    # Packages

    packages.x86_64-linux.jupyter = pkgs.jupyter.override { definitions = kernelspecs; };

    packages.x86_64-linux.default = self.packages.x86_64-linux.jupyter;

    # Applications

    apps.x86_64-linux.jupyter-lab = {
      type = "app";
      program = "${self.packages.x86_64-linux.jupyter}/bin/jupyter-lab";
    };

    apps.x86_64-linux.jupyter-notebook = {
      type = "app";
      program = "${self.packages.x86_64-linux.jupyter}/bin/jupyter-notebook";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.jupyter-lab;
  };
}
