{ lib, call-flake }:
{
  applyPatches =
    {
      pkgs,
      name,
      src,
      patches,
      lockFileEntries ? { },
    }:
    let
      numOfPatches = lib.length patches;

      patchedFlake =
        let
          patched =
            (pkgs.applyPatches {
              inherit name src;
              inherit patches;
              # patches = map pkgs.fetchpatch2 patches;
            }).overrideAttrs
              (
                _: prevAttrs: {
                  outputs = [
                    "out"
                    "narHash"
                  ];
                  installPhase = lib.concatStringsSep "\n" [
                    prevAttrs.installPhase
                    ''
                      ${lib.getExe pkgs.nix} \
                        --extra-experimental-features nix-command \
                        --offline \
                        hash path ./ \
                        > $narHash
                    ''
                  ];
                }
              );

          lockFilePath = "${patched.outPath}/flake.lock";

          lockFile = builtins.unsafeDiscardStringContext (
            lib.generators.toJSON { } (
              if lib.pathExists lockFilePath then
                let
                  original = lib.importJSON lockFilePath;
                in
                {
                  inherit (original) root;
                  nodes = original.nodes // lockFileEntries;
                }
              else
                {
                  nodes.root = { };
                  root = "root";
                }
            )
          );

          flake = {
            inherit (patched) outPath;
            narHash = lib.fileContents patched.narHash;
          };
        in
        (import "${call-flake}/call-flake.nix") lockFile {
          root = {
            sourceInfo = flake;
            subdir = "";
          };
        };
    in
    if numOfPatches == 0 then src else patchedFlake;
}
