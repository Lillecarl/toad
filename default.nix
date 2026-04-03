{
  pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
  },
  pyproject-nix ? import (fetchGit "git@github.com:pyproject-nix/pyproject.nix") {
    inherit (pkgs) lib;
  },
}:
let
  overlay = final: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (python-final: python-prev: {
        textual = python-prev.textual.overridePythonAttrs (old: rec {
          version = "8.2.6";
          src = final.fetchFromGitHub {
            owner = "Textualize";
            repo = "textual";
            rev = "v${version}";
            hash = "sha256-VSgwa817ovlbKnuJx6KCy3osund8PXZ4Sqlh02TkxGA=";
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

        textual-diff-view = python-final.buildPythonPackage rec {
          pname = "textual-diff-view";
          version = "0.1.5";
          pyproject = true;

          src = final.fetchFromGitHub {
            owner = "batrachianai";
            repo = "textual-diff-view";
            rev = "8f8aa2f559a868fc1be4ab503b087c163c3bb531";
            hash = "sha256-+SMxscgHWsCjUIYeU0f4k9TMYxWYBjL2A2PpRSyxAn4=";
          };

          postPatch = ''
            substituteInPlace pyproject.toml \
              --replace 'uv_build>=0.9.18,<0.10.0' 'uv_build>=0.9.18'
          '';

          build-system = with python-final; [ uv-build ];

          dependencies = with python-final; [ textual ];
        };

        rich = python-prev.rich.overridePythonAttrs (old: rec {
          version = "15.0.0";
          src = final.fetchFromGitHub {
            owner = "Textualize";
            repo = "rich";
            rev = "v${version}";
            hash = "sha256-Uk3r6aYhrjYJ8GrMKfdlv3/muK/uUynd4pd1yWCwSOM=";
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

  project = pyproject-nix.lib.project.loadPyprojectDynamic {
    projectRoot = ./.;
  };

  python = pkgs.python314;

  args = project.renderers.buildPythonPackage { inherit python; };

  package =
    python.pkgs.buildPythonPackage (
      args
      // {
        src = ./.;

        pythonRelaxDeps = [
          "aiosqlite"
          "notify-py"
          "platformdirs"
          "click"
          "packaging"
          "pathspec"
          "psutil"
          "typeguard"
        ];

        dependencies =
          args.dependencies or [ ]
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
              "--prefix PATH ${lib.makeBinPath packages}"
            ];
          }
        );
    };
in
package // { inherit args pkgs package; }
