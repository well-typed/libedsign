{ edsign ? { outPath = ./.; revCount = 0; shortRev = "abcdef"; rev = "HEAD"; }
, officialRelease ? false
, coverityUpload ? false
}:

let
  nixcfg = { allowUnfree = true; };
  pkgs   = import <nixpkgs> { config=nixcfg; };

  systems = [ "i686-linux" "x86_64-linux"
             #"x86_64-darwin"
            ];

  version = builtins.readFile ./VERSION +
    (pkgs.lib.optionalString (!officialRelease)
      "-r${toString edsign.revCount}-g${edsign.shortRev}");

  ifNotCoverity = x: if coverityUpload == true  then {} else x;
  ifCoverity    = x: if coverityUpload == false then {} else x;

  jobs = rec {
    ## -- Tarballs -------------------------------------------------------------
    tarball = pkgs.releaseTools.sourceTarball {
      name = "edsign-tarball";
      src  = edsign;
      inherit version;
      buildInputs = with pkgs; [ git xz perl ];
      meta.maintainers = [ "aseipp@pobox.com" ];

      distPhase = ''
        relname=edsign-${version}
        mkdir ../$relname
        cp -prd . ../$relname
        rm -rf ../$relname/.git ../$relname/svn-revision
        echo -n ${version} > ../$relname/VERSION

        mkdir $out/tarballs
        tar cvfJ $out/tarballs/$relname.tar.xz -C .. $relname
      '';
    };

    amalgamation = ifNotCoverity (pkgs.releaseTools.sourceTarball {
      name = "edsign-amalgamation";
      src  = edsign;
      inherit version;
      buildInputs = with pkgs; [ git xz perl perlPackages.ListMoreUtils ];
      meta.maintainers = [ "aseipp@pobox.com" ];

      distPhase = ''
        relname=edsign-${version}-amalg
        mkdir ../$relname-orig ../$relname
        cp -prd . ../$relname-orig
        rm -rf ../$relname-orig/.git ../$relname-orig/svn-revision
        echo -n ${version} > ../$relname-orig/VERSION
        make -C ../$relname-orig distclean # Clean up files
        make -C ../$relname-orig sdistprep # Generate amalgamation
        cp ../$relname-orig/lib/edsign-amalg.c ../$relname/edsign.c
        cp ../$relname-orig/etc/amalg/Makefile.in ../$relname/Makefile
        for x in LICENSE.txt README.md VERSION CHANGELOG.md lib/edsign.h; do
          cp ../$relname-orig/$x ../$relname
        done
        mkdir $out/tarballs
        tar cvfJ $out/tarballs/$relname.tar.xz -C .. $relname
      '';
    });

    ## -- Build ----------------------------------------------------------------
    build = ifNotCoverity (pkgs.lib.genAttrs systems (system:
      with import <nixpkgs> { inherit system; config=nixcfg; };

      releaseTools.nixBuild {
        name = "edsign";
        inherit version;
        src  = tarball;
        meta.maintainers = [ "aseipp@pobox.com" ];

        enableParallelBuilding = true;
        doCheck = false;

        installPhase = "make install PREFIX=$out";
      }
    ));

    build-amalgamation = ifNotCoverity (pkgs.lib.genAttrs systems (system:
      with import <nixpkgs> { inherit system; config=nixcfg; };

      releaseTools.nixBuild {
        name = "edsign";
        inherit version;
        src  = amalgamation;
        meta.maintainers = [ "aseipp@pobox.com" ];

        doCheck     = false;
        dontInstall = true;
      }
    ));

    ## -- Tests ----------------------------------------------------------------
    tests = ifNotCoverity (pkgs.lib.genAttrs systems (system:
      with import <nixpkgs> { inherit system; config=nixcfg; };

      releaseTools.nixBuild {
        name = "edsign-test";
        inherit version;
        src  = tarball;
        buildInputs = with pkgs; [ perl perlPackages.ListMoreUtils ];
        meta.maintainers = [ "aseipp@pobox.com" ];

        enableParallelBuilding = true;
        doCheck      = true;
        checkFlags   = [ "DEBUG=1" ];
        dontInstall  = true;
      }
    ));

    ## -- Coverity -------------------------------------------------------------
    coverity = ifCoverity (
      with import <nixpkgs> { system = "x86_64-linux"; config=nixcfg; };

      releaseTools.coverityAnalysis {
        name = "edsign-coverity";
        inherit version;
        src  = tarball;
        buildInputs = with pkgs; [ perl perlPackages.ListMoreUtils ];
        meta.maintainers = [ "aseipp@pobox.com" ];

        buildPhase = "make all check DEBUG=1";
        doCheck    = false;
      }
    );

    ## -- Clang analyzer -------------------------------------------------------
    clang-analyzer = ifNotCoverity (
      with import <nixpkgs> { system = "x86_64-linux"; config=nixcfg; };

      releaseTools.clangAnalysis {
        name = "edsign-clang-analyzer";
        inherit version;
        src  = tarball;
        buildInputs = with pkgs; [ perl perlPackages.ListMoreUtils ];
        meta.maintainers = [ "aseipp@pobox.com" ];

        buildPhase = "make all check DEBUG=1";
        doCheck    = false;
      }
    );

    ## -- Frama-C --------------------------------------------------------------
#    frama-c = ifNotCoverity (
#      with import <nixpkgs> { system = "x86_64-linux"; config=nixcfg; };
#
#      releaseTools.nixBuild {
#        name = "edsign-frama-c";
#        inherit version;
#        src  = tarball;
#        buildInputs = with pkgs; [ framac perl perlPackages.ListMoreUtils ];
#        meta.maintainers = [ "aseipp@pobox.com" ];
#
#        buildPhase  = "make framalyze DEBUG=1";
#        doCheck     = false;
#        dontInstall = true;
#      }
#    );

    ## -- Coverage -------------------------------------------------------------
    coverage = ifNotCoverity (
      with import <nixpkgs> { system = "x86_64-linux"; config=nixcfg; };

      releaseTools.coverageAnalysis {
        name = "edsign-coverage";
        inherit version;
        src  = tarball;
        buildInputs = with pkgs; [ perl perlPackages.ListMoreUtils ];
        meta.maintainers = [ "aseipp@pobox.com" ];

        enableParallelBuilding = true;
        makeFlags = [ "DEBUG=1" ];
      }
    );

    ## -- Debian build ---------------------------------------------------------

    #deb_debian7i386   = ifNotCoverity
    #  (makeDeb_i686 (diskImageFuns: diskImageFuns.debian7i386) 60);
    #deb_debian7x86_64 = ifNotCoverity
    #  (makeDeb_x86_64 (diskImageFunsFun: diskImageFunsFun.debian7x86_64) 60);

    ## -- Ubuntu builds --------------------------------------------------------

    #deb_ubuntu1004i386   = ifNotCoverity
    #  (makeDeb_i686 (diskImageFuns: diskImageFuns.ubuntu1004i386) 50);
    #deb_ubuntu1004x86_64 = ifNotCoverity
    #  (makeDeb_x86_64 (diskImageFuns: diskImageFuns.ubuntu1004x86_64) 50);
    #deb_ubuntu1204i386   = ifNotCoverity
    #  (makeDeb_i686 (diskImageFuns: diskImageFuns.ubuntu1204i386) 60);
    #deb_ubuntu1204x86_64 = ifNotCoverity
    #  (makeDeb_x86_64 (diskImageFuns: diskImageFuns.ubuntu1204x86_64) 60);
    #deb_ubuntu1404i386   = ifNotCoverity
    #  (makeDeb_i686 (diskImageFuns: diskImageFuns.ubuntu1404i386) 60);
    #deb_ubuntu1404x86_64 = ifNotCoverity
    #  (makeDeb_x86_64 (diskImageFuns: diskImageFuns.ubuntu1404x86_64) 60);

    ## -- Fedora builds --------------------------------------------------------

    #rpm_fedora20i386   = ifNotCoverity
    #  (makeRPM_i686 (diskImageFuns: diskImageFuns.fedora20i386) 70);
    #rpm_fedora20x86_64 = ifNotCoverity
    #  (makeRPM_x86_64 (diskImageFunsFun: diskImageFunsFun.fedora20x86_64) 70);

    ## -- Release build --------------------------------------------------------
    release = ifNotCoverity (pkgs.releaseTools.aggregate
      { name = "edsign-${version}";
        constituents =
          [ tarball amalgamation
            build-amalgamation.i686-linux build-amalgamation.x86_64-linux # build-amalgamation.x86_64-darwin
            build.i686-linux build.x86_64-linux # build.x86_64-darwin
            tests.i686-linux tests.x86_64-linux # tests.x864_64-darwin
           #deb_debian7i386    deb_debian7x86_64
           #deb_ubuntu1004i386 deb_ubuntu1004x86_64
           #deb_ubuntu1204i386 deb_ubuntu1204x86_64
           #deb_ubuntu1404i386 deb_ubuntu1404x86_64
           #rpm_fedora20i386   rpm_fedora20x86_64
            coverage
          ];
        meta.description = "Release-critical builds";
        meta.maintainers = [ "aseipp@pobox.com" ];
      }
    );
  };

  ## -- RPM/Deb utilities ----------------------------------------------------

  makeDeb_i686 = makeDeb "i686-linux";
  makeDeb_x86_64 = makeDeb "x86_64-linux";

  makeDeb =
    system: diskImageFun: prio:

    with import <nixpkgs> { inherit system; };

    releaseTools.debBuild {
      name = "edsign-deb";
      src = jobs.tarball;
      diskImage = (diskImageFun vmTools.diskImageFuns) {};
      memSize = 1024;
      meta.schedulingPriority = prio;
      debMaintainer = "Austin Seipp <aseipp@pobox.com>";
      doInstallCheck = false;
      preInstall = "export INSTALLPREFIX=/usr";
    };


  makeRPM_i686   = makeRPM "i686-linux";
  makeRPM_x86_64 = makeRPM "x86_64-linux";

  makeRPM =
    system: diskImageFun: prio:

    with import <nixpkgs> { inherit system; };

    releaseTools.rpmBuild rec {
      name = "edsign-rpm";
      src = jobs.tarball;
      diskImage = (diskImageFun vmTools.diskImageFuns) {};
      memSize = 1024;
      meta.schedulingPriority = prio;
      preInstall = "export INSTALLPREFIX=/usr";
    };

in jobs
