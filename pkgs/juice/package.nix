{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "juice";
  version = "11.1.1";

  src = fetchFromGitHub {
    owner = "Automattic";
    repo = "juice";
    rev = "v${version}";
    hash = "sha256-ZVP3O3eSbJUj6MFTy4SJSihq6hOdG64fQhYaJKHJ+Dw=";
  };

  npmDepsHash = "sha256-cKEo50geN9kLtKo1SFrPpFPIeW+8c2bQJyRce6OOVS0=";

  dontNpmBuild = true;

  meta = {
    description = "Inline CSS stylesheets into HTML";
    homepage = "https://github.com/Automattic/juice";
    license = lib.licenses.mit;
    mainProgram = "juice";
  };
}
