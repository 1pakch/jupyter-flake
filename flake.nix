{
  description = "A flake with Jupyter package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.jupyter = nixpkgs.legacyPackages.x86_64-linux.jupyter;
    packages.x86_64-linux.default = self.packages.x86_64-linux.jupyter;
    apps.x86_64-linux.default = {
      type = "app";
      program = "${self.packages.x86_64-linux.jupyter}/bin/jupyter-lab";
    };
  };
}
