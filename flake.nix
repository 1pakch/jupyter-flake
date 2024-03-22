{
  description = "A flake with Jupyter package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    pythonEnv = pkgs.python3.withPackages (ps: [ps.ipykernel ps.numpy]);
    rEnv = pkgs.rWrapper.override { packages = [ pkgs.rPackages.IRkernel ]; };
    ks-utils = import ./kernelspec-utils.nix;
    kernelspecs = {
      pykernel = ks-utils.fromPythonEnv {
        env = pythonEnv;
        suffix = "(numpy)";
      };
      rkernel = ks-utils.fromREnv {
        env = rEnv;
        suffix = "(barebone)";
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
