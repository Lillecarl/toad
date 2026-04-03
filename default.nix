{
  pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
  },
}:
let
  overlay = final: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (python-final: python-prev: {
        textual = python-prev.textual.overridePythonAttrs (old: rec {
          version = "8.2.2";
          src = final.fetchFromGitHub {
            owner = "Textualize";
            repo = "textual";
            rev = "v${version}";
            hash = "sha256-+yG1LwuwPWkrJw+yw7gVgdsjJGPxdfV+ygUXDQoHTTQ=";
          };
        });

        textual-serve = python-prev.textual-serve.overridePythonAttrs (old: rec {
          version = "1.1.2";
          src = final.fetchFromGitHub {
            owner = "Textualize";
            repo = "textual-serve";
            rev = "v${version}";
            hash = "sha256-I6sgJ5yeHmGfJncPogyneEdJQz4byRT5sEVRGpr7vuE=";
          };
        });

        textual-speedups = python-prev.textual-speedups.overridePythonAttrs (old: rec {
          version = "0.2.1";
          src = final.fetchFromGitHub {
            owner = "willmcgugan";
            repo = "textual-speedups";
            rev = "v${version}";
            hash = "sha256-zsDA8qPpeiOlmL18p4pItEgXQjgrQEBVRJazrGJT9Bw=";
          };
        });

        rich = python-prev.rich.overridePythonAttrs (old: rec {
          version = "14.3.3";
          src = final.fetchFromGitHub {
            owner = "Textualize";
            repo = "rich";
            rev = "v${version}";
            hash = "sha256-6udVO7N17ineQozlCG/tI9jJob811gqb4GtY50JZFb0=";
          };
        });
      })
    ];
  };

  pkgs' = pkgs.extend overlay;
in
let
  pkgs = pkgs';
  inherit (pkgs) lib;

  pyproject-nix = import /home/lillecarl/Code/pyproject.nix { inherit lib; };

  project = pyproject-nix.lib.project.loadPyprojectDynamic {
    projectRoot = ./.;
  };

  python = pkgs.python314;

  arg = project.renderers.buildPythonPackage { inherit python; };

  package =
    python.pkgs.buildPythonPackage (
      arg
      // {
        src = ./.;

        pythonRelaxDeps = [
          "aiosqlite"
          "notify-py"
          "platformdirs"
        ];

        dependencies =
          arg.dependencies or [ ]
          ++ (with python.pkgs; [
            pythonRelaxDepsHook
          ]);
      }
    )
    // {
      withPackages =
        packages:
        package.overrideAttrs (
          final: prev: {
            makeWrapperArgs = prev.makeWrapperArgs or [ ] ++ [
              "--prefix PATH ${
                lib.makeBinPath packages
              }"
            ];
          }
        );
    };
in
package // { inherit package; }
