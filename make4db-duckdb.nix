{
  lib,
  buildPythonPackage,
  setuptools,
  make4db-api,
  duckdb
}:
buildPythonPackage {
  pname     = "make4db-duckdb";
  version   = "0.1.0";
  pyproject = true;
  src       = ./.;

  propagatedBuildInputs = [ make4db-api duckdb ];
  nativeBuildInputs     = [ setuptools ];
  doCheck               = false;

  meta = with lib; {
    description = "DuckDB provider for make4db tool";
    maintainers = with maintainers; [ padhia ];
  };
}
