{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
}:

buildGoModule (finalAttrs: {
  pname = "trenchman";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "athos";
    repo = "trenchman";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HhTANZlaXMH6dePyRzmbOQpxjWDdzY0dL0cwjH6f6s0=";
  };

  vendorHash = "sha256-1o1mkg8fagjqPzL6ivOVJ8+8Zj6N9bRBZr/LktWnPco=";

  # Matches upstream's .goreleaser.yml.
  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  # Racy: it reads from an empty bytes.Buffer before a goroutine writes
  # to it, and gets EOF if the read wins (~0.25% of runs).
  checkFlags = [ "-skip=^TestReadLine$" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Standalone nREPL/prepl client written in Go";
    homepage = "https://github.com/athos/trenchman";
    license = lib.licenses.mit;
    mainProgram = "trench";
  };
})
