# Built from the upstream monorepo, so dependencies come from upstream's
# own yarn.lock rather than a lockfile we generate and maintain.  The npm
# `mjml` tarball ships no lockfile, which is the only reason to vendor one.
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  nodejs,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mjml";
  version = "5.4.1";

  src = fetchFromGitHub {
    owner = "mjmlio";
    repo = "mjml";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GVAAu54DbcEVRR6wBv802kTAnILrMPFs3zulLBr/9OI=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/yarn.lock";
    hash = "sha256-w9zJn8ugSTvpVYz1/s3hdDb4JkgSl9Mum7iXhoYRkfY=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    nodejs
    makeWrapper
  ];

  # Upstream's `yarn build` is `lerna run build`, which only runs each
  # package's `babel src --out-dir lib`; doing that directly avoids
  # lerna.  mjml-browser is a separate webpack bundle that upstream's
  # build skips too.
  buildPhase = ''
    runHook preBuild
    for pkg in packages/*; do
      [ "$pkg" = packages/mjml-browser ] && continue
      (cd "$pkg" && node ../../node_modules/.bin/babel src --out-dir lib --root-mode upward)
    done
    runHook postBuild
  '';

  doCheck = true;

  # The packages with test suites.  Runs before install prunes mocha.
  checkPhase = ''
    runHook preCheck
    for dir in packages/mjml/test packages/mjml-core/tests packages/mjml-parser-xml/test; do
      (cd "$(dirname "$dir")" && node ../../node_modules/.bin/mocha "$(basename "$dir")/*.test.js")
    done
    runHook postCheck
  '';

  # Re-running the install with --production prunes devDependencies
  # (babel, lerna, eslint, mocha) from the hoisted node_modules, leaving
  # the workspace packages linked in as relative symlinks.
  installPhase = ''
    runHook preInstall

    yarn install --offline --frozen-lockfile --ignore-scripts --production \
      --no-progress --non-interactive
    rm -r node_modules/mjml-browser packages/mjml-browser
    rm -rf packages/*/{src,test,tests}

    mkdir -p $out/lib/mjml
    cp -r node_modules packages package.json $out/lib/mjml/
    makeWrapper ${lib.getExe nodejs} $out/bin/mjml \
      --add-flags $out/lib/mjml/packages/mjml/bin/mjml

    runHook postInstall
  '';

  meta = {
    description = "Responsive email framework that compiles MJML markup to HTML";
    homepage = "https://mjml.io";
    changelog = "https://github.com/mjmlio/mjml/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "mjml";
    platforms = nodejs.meta.platforms;
  };
})
