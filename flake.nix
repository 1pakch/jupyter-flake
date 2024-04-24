{
  description = "Jupyter server with pluggable nix flake kernels";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    r-mofa2-env.url = "github:1pakch/r-mofa2-env";
  };

  outputs = { self, nixpkgs, r-mofa2-env }: let

    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    ks-utils = import ./kernelspec-utils.nix;
    kernelspecs = {

      py-pandas-kernel = ks-utils.fromPythonEnv {
        env = pkgs.python3.withPackages (ps: [
          ps.ipykernel
          ps.pandas
        ]);
        suffix = "(pandas)";
      };

      r-mofa2-kernel = ks-utils.fromREnv {
        env = r-mofa2-env.packages.x86_64-linux.default;
        suffix = "(mofa2)";
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
