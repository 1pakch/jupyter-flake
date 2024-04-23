rec {

  # A utility function to generate kernel names visible in Jupyter UI
  makeDisplayName = {
    interpreter-name,
    suffix ? ""
  }:
    if suffix != ""
      then interpreter-name + " " + suffix
      else interpreter-name;

  # Generates a Jupyter kernel definition from a Python environment
  # (e.g. created using `python3.withPackages`)
  fromPythonEnv = { env, name ? null, suffix ? ""}: {
    displayName = makeDisplayName {
      interpreter-name = if name == null then "Python ${env.pythonVersion}" else name;
      suffix = suffix;
    };
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

  # Generates a Jupyter kernel definition from an R envirionment
  # (e.g. created using `rWrapper`)
  fromREnv = { env, name ? null, suffix ? ""} : {
    displayName = makeDisplayName {
      interpreter-name = if name == null then "R" else name;
      suffix = suffix;
    };
    argv = [
      "${env}/bin/R"
      "--slave"
      "-e"
      "IRkernel::main()"
      "--args"
      "{connection_file}"
    ];
    language = "R";
    logo32 = null;
    logo64 = null;
  };

  # Writes out a folder with kernel specs that can be used by Jupyter
  # (takes an attrset of kernel definitions as input)
  # Taken from nixpkgs.
  materialize = {
    lib,
    stdenv,
    definitions
  }: with lib; stdenv.mkDerivation {

    name = "jupyter-kernels";

    src = "/dev/null";

    unpackCmd = "mkdir jupyter_kernels";

    installPhase =  ''
      mkdir kernels

      ${concatStringsSep "\n" (mapAttrsToList (kernelName: unfilteredKernel:
        let
          allowedKernelKeys = ["argv" "displayName" "language" "interruptMode" "env" "metadata" "logo32" "logo64" "extraPaths"];
          kernel = filterAttrs (n: v: (any (x: x == n) allowedKernelKeys)) unfilteredKernel;
          config = builtins.toJSON (
            kernel
            // {display_name = if (kernel.displayName != "") then kernel.displayName else kernelName;}
            // (optionalAttrs (kernel ? interruptMode) { interrupt_mode = kernel.interruptMode; })
          );
          extraPaths = kernel.extraPaths or {}
            // lib.optionalAttrs (kernel.logo32 != null) { "logo-32x32.png" = kernel.logo32; }
            // lib.optionalAttrs (kernel.logo64 != null) { "logo-64x64.png" = kernel.logo64; }
          ;
          linkExtraPaths = lib.mapAttrsToList (name: value: "ln -s ${value} 'kernels/${kernelName}/${name}';") extraPaths;
        in ''
          mkdir 'kernels/${kernelName}';
          echo '${config}' > 'kernels/${kernelName}/kernel.json';
          ${lib.concatStringsSep "\n" linkExtraPaths}
        '') definitions)}

      mkdir $out
      cp -r kernels $out
    '';

    meta = {
      description = "Writes out kernel definitions so that they can be read by Jupyter";
    };
  };
}
