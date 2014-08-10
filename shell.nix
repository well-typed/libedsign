let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;

  env = with pkgs; rec {
    libedsignEnv = stdenv.mkDerivation rec {
      name = "libedsign-env";
      src  = ./.;
      buildInputs =
        [ git xz clang gcc framac compcert
	  perl perlPackages.ListMoreUtils
	];
    };
  };
in env
