{
  description = "A flake with Jupyter package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    pythonEnv = pkgs.python3.withPackages (ps: [ps.ipykernel ps.numpy]);
    kernelspecs = {
      pythonenv = let
        env = pythonEnv;
      in {
        displayName = "Python 3 with numpy";
        argv = [
          env.interpreter
          "-m"
          "ipykernel_launcher"
          "-f"
          "{connection_file}"
        ];
        language = "python";
        logo32 = "${env}/${env.sitePackages}/ipykernel/resources/logo-32x32.png";
        logo64 = "${env}/${env.sitePackages}/ipykernel/resources/logo-64x64.png";
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
