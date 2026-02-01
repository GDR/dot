# Minimal pre-commit package to avoid Swift dependency on Darwin
{ lib, python3Packages, git }:

python3Packages.buildPythonApplication rec {
  pname = "pre-commit";
  version = "4.0.1";
  format = "setuptools";

  src = python3Packages.fetchPypi {
    pname = "pre_commit";
    inherit version;
    hash = "sha256-gJBaw3WVjARExl6c6+vZSLPNtRjzNaCRpnConWUhOdI=";
  };

  propagatedBuildInputs = with python3Packages; [
    cfgv
    identify
    nodeenv
    pyyaml
    virtualenv
  ];

  # Skip tests entirely - no test files in PyPI tarball
  doCheck = false;
  dontUsePytestCheck = true;
  pythonImportsCheck = [ "pre_commit" ];

  meta = with lib; {
    description = "A framework for managing and maintaining multi-language pre-commit hooks";
    homepage = "https://pre-commit.com/";
    license = licenses.mit;
    mainProgram = "pre-commit";
  };
}
