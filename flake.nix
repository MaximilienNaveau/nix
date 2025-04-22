{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/develop";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # keep-sorted start block=yes

    patch-0-crocoddyl = {
      url = "https://github.com/NixOS/nixpkgs/pull/391300.patch";
      flake = false;
    };
    patch-1-aligator = {
      url = "https://github.com/NixOS/nixpkgs/pull/390922.patch";
      flake = false;
    };
    patch-brax = {
      url = "https://github.com/NixOS/nixpkgs/pull/393394.patch";
      flake = false;
    };
    patch-hpp = {
      url = "https://github.com/nim65s/nixpkgs/pull/3.patch";
      flake = false;
    };
    patch-mim-solvers = {
      url = "https://github.com/NixOS/nixpkgs/pull/391930.patch";
      flake = false;
    };
    patch-mim-solvers-2 = {
      url = "https://github.com/NixOS/nixpkgs/pull/397664.patch";
      flake = false;
    };
    patch-osg = {
      url = "https://github.com/NixOS/nixpkgs/pull/384430.patch";
      flake = false;
    };
    patch-piqp = {
      url = "https://github.com/NixOS/nixpkgs/pull/374657.patch";
      flake = false;
    };
    patch-qtwebengine = {
      url = "https://github.com/NixOS/nixpkgs/pull/386846.patch";
      flake = false;
    };
    patch-qtwebengine-2 = {
      url = "https://github.com/NixOS/nixpkgs/pull/383990.patch";
      flake = false;
    };
    src-agimus-msgs = {
      url = "github:agimus-project/agimus_msgs";
      flake = false;
    };
    src-colmpc = {
      url = "github:agimus-project/colmpc";
      flake = false;
    };
    src-example-parallel-robots = {
      url = "github:gepetto/example-parallel-robots";
      flake = false;
    };
    src-franka-description = {
      url = "github:agimus-project/franka_description";
      flake = false;
    };
    # gepetto-viewer has a fix to understand AMENT_PREFIX_PATH in #239/devel
    src-gepetto-viewer = {
      url = "github:Gepetto/gepetto-viewer/devel";
      flake = false;
    };
    src-toolbox-parallel-robots = {
      url = "github:gepetto/toolbox-parallel-robots";
      flake = false;
    };

    # keep-sorted end
  };
  outputs =
    inputs:
    let
      pkgsForPatching = inputs.nixpkgs.legacyPackages.x86_64-linux;
      patches = [
        # keep-sorted start
        inputs.patch-0-crocoddyl
        inputs.patch-1-aligator
        inputs.patch-brax
        inputs.patch-hpp
        inputs.patch-mim-solvers
        inputs.patch-mim-solvers-2
        inputs.patch-osg
        inputs.patch-piqp
        inputs.patch-qtwebengine
        inputs.patch-qtwebengine-2
        # keep-sorted end
      ];
      patchedNixpkgs = (
        pkgsForPatching.applyPatches {
          inherit patches;
          name = "patched nixpkgs";
          src = inputs.nixpkgs;
        }
      );
      overlay = (
        final: prev:
        {
          inherit (inputs)
            # keep-sorted start
            src-colmpc
            # keep-sorted end
            ;
          # keep-sorted start block=yes
          gepetto-viewer = prev.gepetto-viewer.overrideAttrs {
            src = inputs.src-gepetto-viewer;
          };
          # keep-sorted end
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (
              python-final: python-prev:
              {
                inherit (inputs)
                  # keep-sorted start
                  src-example-parallel-robots
                  src-toolbox-parallel-robots
                  # keep-sorted end
                  ;
                brax = python-prev.brax.overrideAttrs {
                  # depends on mujoco
                  # which is broken on darwin
                  meta.broken = final.stdenv.hostPlatform.isDarwin;
                };
                colmpc = python-final.toPythonModule (
                  final.colmpc.override {
                    pythonSupport = true;
                    python3Packages = python-final;
                  }
                );
              }
              // final.lib.filesystem.packagesFromDirectoryRecursive {
                inherit (python-final) callPackage;
                directory = ./py-pkgs;
              }
            )
          ];
          rosPackages = prev.rosPackages // {
            humble = prev.rosPackages.humble.overrideScope (
              humble-final: humble-prev:
              {
                inherit (inputs)
                  # keep-sorted start
                  src-agimus-msgs
                  # keep-sorted end
                  ;
                franka-description = humble-prev.franka-description.overrideAttrs {
                  src = inputs.src-franka-description;
                  # depends on pyside2 which is broken on darwin
                  meta.broken = final.stdenv.hostPlatform.isDarwin;
                };
              }
              // final.lib.filesystem.packagesFromDirectoryRecursive {
                inherit (humble-final) callPackage;
                directory = ./humble-pkgs;
              }
            );
            jazzy = prev.rosPackages.jazzy.overrideScope (
              jazzy-final: _jazzy-prev:
              {
                inherit (inputs)
                  # keep-sorted start
                  src-agimus-msgs
                  # keep-sorted end
                  ;
              }
              // final.lib.filesystem.packagesFromDirectoryRecursive {
                inherit (jazzy-final) callPackage;
                directory = ./jazzy-pkgs;
              }
            );
          };
        }
        // prev.lib.filesystem.packagesFromDirectoryRecursive {
          inherit (final) callPackage;
          directory = ./pkgs;
        }
      );
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      imports = [ inputs.treefmt-nix.flakeModule ];
      flake = {
        overlays.default = overlay;
        templates.default = {
          path = ./template;
          description = "A template for use with gepetto/nix";
        };
      };
      perSystem =
        {
          lib,
          pkgs,
          self',
          system,
          ...
        }:
        {
          _module.args.pkgs = import patchedNixpkgs {
            inherit system;
            overlays = [
              inputs.nix-ros-overlay.overlays.default
              overlay
            ];
          };
          checks =
            let
              devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
              packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
            in
            lib.filterAttrs (_n: v: v.meta.available && !v.meta.broken) (devShells // packages);
          devShells = {
            default = pkgs.mkShell {
              name = "Gepetto Main Dev Shell";
              packages = [
                # keep-sorted start
                pkgs.colcon
                self'.packages.python
                self'.packages.ros
                # keep-sorted end
              ];
            };
            ms = pkgs.mkShell {
              name = "Dev Shell for Maxime";
              inputsFrom = [ pkgs.python3Packages.crocoddyl ];
              packages = [
                (pkgs.python3.withPackages (p: [
                  # keep-sorted start
                  p.example-parallel-robots
                  p.fatrop
                  p.gepetto-gui
                  p.ipython
                  p.matplotlib
                  p.mim-solvers
                  p.opencv4
                  p.pandas
                  p.proxsuite
                  p.quadprog
                  # keep-sorted end
                ]))
              ];
              shellHook = ''
                export PYTHONPATH=${
                  lib.concatStringsSep ":" [
                    "$PWD/src/cobotmpc"
                    "$PWD/install/${pkgs.python3.sitePackages}"
                    "$PYTHONPATH"
                  ]
                }
              '';
            };
          };
          packages = lib.filterAttrs (_n: v: v.meta.available && !v.meta.broken) (
            {
              python = pkgs.python3.withPackages (p: [
                # keep-sorted start
                p.crocoddyl
                p.gepetto-gui
                p.hpp-corba
                p.ipython
                p.matplotlib
                # keep-sorted end
              ]);
              ros =
                with pkgs.rosPackages.humble;
                buildEnv {
                  paths = [
                    # keep-sorted start
                    pkgs.python3Packages.example-robot-data # for availability in AMENT_PREFIX_PATH
                    pkgs.python3Packages.hpp-tutorial # for availability in AMENT_PREFIX_PATH
                    ros-core
                    turtlesim
                    # keep-sorted end
                  ];
                };
            }
            // {
              inherit (pkgs)
                # keep-sorted start
                aligator
                colmpc
                crocoddyl
                example-robot-data
                gepetto-viewer
                hpp-affordance
                hpp-affordance-corba
                hpp-baxter
                hpp-bezier-com-traj
                hpp-centroidal-dynamics
                hpp-constraints
                hpp-corbaserver
                hpp-core
                hpp-doc
                hpp-environments
                hpp-gepetto-viewer
                hpp-gui
                hpp-manipulation
                hpp-manipulation-corba
                hpp-manipulation-urdf
                hpp-pinocchio
                hpp-plot
                hpp-practicals
                hpp-romeo
                hpp-statistics
                hpp-template-corba
                hpp-tutorial
                hpp-universal-robot
                hpp-util
                mim-solvers
                pinocchio
                # keep-sorted end
                ;
            }
            // lib.mapAttrs' (n: lib.nameValuePair "py-${n}") {
              inherit (pkgs.python3Packages)
                # keep-sorted start
                aligator
                brax
                colmpc
                crocoddyl
                example-parallel-robots
                example-robot-data
                gepetto-gui
                hpp-corba
                hpp-corbaserver
                hpp-doc
                hpp-environments
                hpp-gepetto-viewer
                hpp-gui
                hpp-manipulation-corba
                hpp-plot
                hpp-practicals
                hpp-romeo
                hpp-tutorial
                hpp-universal-robot
                mim-solvers
                pinocchio
                toolbox-parallel-robots
                # keep-sorted end
                ;
            }
            // lib.mapAttrs' (n: lib.nameValuePair "ros-humble-${n}") {
              inherit (pkgs.rosPackages.humble)
                # keep-sorted start
                agimus-msgs
                franka-description
                linear-feedback-controller
                linear-feedback-controller-msgs
                # keep-sorted end
                ;
            }
            // lib.mapAttrs' (n: lib.nameValuePair "ros-jazzy-${n}") {
              inherit (pkgs.rosPackages.jazzy)
                # keep-sorted start
                agimus-msgs
                linear-feedback-controller
                linear-feedback-controller-msgs
                # keep-sorted end
                ;
            }
          );
          treefmt = {
            settings.global.excludes = [
              ".envrc"
              ".git-blame-ignore-revs"
              "LICENSE"
            ];
            programs = {
              # keep-sorted start
              deadnix.enable = true;
              keep-sorted.enable = true;
              mdformat.enable = true;
              nixfmt.enable = true;
              yamlfmt.enable = true;
              # keep-sorted end
            };
          };
        };
    };
}
