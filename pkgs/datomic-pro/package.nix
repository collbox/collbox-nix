{
  lib,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  jre_headless,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "datomic-pro";
  version = "1.0.7705";

  src = fetchzip {
    url = "https://datomic-pro-downloads.s3.amazonaws.com/${finalAttrs.version}/datomic-pro-${finalAttrs.version}.zip";
    hash = "sha256-r7y17d4dufLfKJB7gv8feTLlvs1nuoRU2/TueR9wd9I=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  # The distribution's bin/ scripts `cd` into the install directory, so
  # relative paths in a properties file resolve inside the store, and
  # they run whatever `java` is on PATH.  These wrappers do what the
  # scripts do -- same classpath, entry points and JVM defaults -- from
  # the caller's directory with a pinned JRE.  JVM options can be added
  # or overridden (e.g. -Xmx4g) with DATOMIC_JAVA_OPTS, as for bin/run.
  #
  # Don't set `log-dir` in the properties: the transactor then reloads
  # logback from the relative path bin/logback.xml, which only exists
  # when run from the install directory.  Without it, logging follows
  # bin/logback.xml from the classpath, writing to
  # ${DATOMIC_LOG_DIR:-log}; set -DDATOMIC_LOG_DIR or
  # -Dlogback.configurationFile in DATOMIC_JAVA_OPTS to change that.
  #
  # presto-server (analytics) and the peer jar aren't needed to run a
  # transactor and make up most of the download.
  installPhase =
    let
      share = "${placeholder "out"}/share/datomic-pro";
      classpath = lib.concatStringsSep ":" [
        "${share}/resources"
        "${share}/datomic-transactor-pro-${finalAttrs.version}.jar"
        "${share}/lib/*"
        "${share}/samples/clj"
        "${share}/bin"
      ];
      java = "${jre_headless}/bin/java";
    in
    ''
      runHook preInstall

      rm -r presto-server peer-*.jar bin/*.cmd
      mkdir -p ${share}
      cp -r . ${share}

      makeWrapper ${java} $out/bin/datomic-transactor \
        --add-flags "-server -Xms1g -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=50" \
        --add-flags '$DATOMIC_JAVA_OPTS' \
        --add-flags "-cp '${classpath}' clojure.main --main datomic.launcher"

      makeWrapper ${java} $out/bin/datomic \
        --add-flags "-server -Xms1g -Xmx1g" \
        --add-flags '$DATOMIC_JAVA_OPTS' \
        --add-flags "-cp '${classpath}' clojure.main -i ${share}/bin/bridge.clj --main datomic"

      runHook postInstall
    '';

  meta = {
    description = "Datomic Pro transactor and command-line tools";
    homepage = "https://docs.datomic.com/";
    changelog = "https://docs.datomic.com/changes/pro.html";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    mainProgram = "datomic-transactor";
    inherit (jre_headless.meta) platforms;
  };
})
