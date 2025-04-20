{
  lib,
  buildPythonPackage,
  setuptools,
  make4db-api,
  duckdb
}:
buildPythonPackage {
  pname     = "make4db-duckdb";
  version   = "0.1.2";
  pyproject = true;
  src       = ./.;

  propagatedBuildInputs = [ make4db-api duckdb ];
  nativeBuildInputs     = [ setuptools ];
  doCheck               = false;

  meta = with lib; {
    description = "make4db provider for DuckDB";
    maintainers = with maintainers; [ padhia ];
  };
}
