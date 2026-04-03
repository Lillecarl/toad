let
  default = import ./. {};
  inherit (default) pkgs;
in
pkgs.mkShell {
  packages = [
    default.package
  ];
}

