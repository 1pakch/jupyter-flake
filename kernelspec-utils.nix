rec {

  makeDisplayName = {
    interpreter-name,
    suffix ? ""
  }:
    if suffix != ""
      then interpreter-name + " " + suffix
      else interpreter-name;

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

}
