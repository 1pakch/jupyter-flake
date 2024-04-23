{
  description = "Jupyter server with pluggable nix flake kernels";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let

    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    ks-utils = import ./kernelspec-utils.nix;
    kernelspecs = {

      pykernel = ks-utils.fromPythonEnv {
        env = pkgs.python3.withPackages (ps: [
          ps.ipykernel
          ps.numpy
        ]);
        suffix = "(numpy)";
      };

      rkernel = ks-utils.fromREnv {
        env = pkgs.rWrapper.override {
          packages = [
            pkgs.rPackages.IRkernel
          ];
        };
        suffix = "(barebone)";
      };

    };

    kernelspecs-folder = ks-utils.materialize {
      lib = pkgs.lib;
      stdenv = pkgs.stdenv;
      definitions = kernelspecs; 
    };

    # Taken from nixpkgs - we need it here in order to be able to customize `extraLibs`
    jupyter-env = (
      pkgs.python3.buildEnv.override {
        extraLibs = [
          pkgs.python3.pkgs.notebook
          pkgs.python3.pkgs.jupytext
        ];
        makeWrapperArgs = ["--set JUPYTER_PATH ${kernelspecs-folder}"];
      }
    ).overrideAttrs(oldAttrs: {
      meta = oldAttrs.meta // { mainProgram = "jupyter-lab"; };
    });

  in {

    # Packages

    packages.x86_64-linux.jupyter-env = jupyter-env;

    packages.x86_64-linux.default = self.packages.x86_64-linux.jupyter-env;

    # Applications

    apps.x86_64-linux.jupyter-lab = {
      type = "app";
      program = "${self.packages.x86_64-linux.jupyter-env}/bin/jupyter-lab";
    };

    apps.x86_64-linux.jupyter-notebook = {
      type = "app";
      program = "${self.packages.x86_64-linux.jupyter-env}/bin/jupyter-notebook";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.jupyter-lab;
  };
}
