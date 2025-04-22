{
  lib,
  stdenv,

  fetchFromGitHub,

  # nativeBuildInputs
  cmake,
  eigen,
  python3Packages,
  ament-cmake,
  ament-cmake-cppcheck,
  ament-cmake-cpplint,
  ament-cmake-flake8,
  ament-cmake-pep257,
  ament-cmake-uncrustify,

  # propagatedBuildInputs
  builtin-interfaces,
  geometry-msgs,
  rosidl-default-generators,
  rosidl-default-runtime,
  sensor-msgs,
  tf2-eigen,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "linear-feedback-controller-msgs";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "loco-3d";
    repo = "linear-feedback-controller-msgs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-iolp/25VccP7knwRUOj4eQ5kGlcvWEiCfTYHkx/AUrA=";
  };

  nativeBuildInputs = [
    cmake
    eigen
    python3Packages.python
  ];

  propagatedBuildInputs = [
    ament-cmake
    ament-cmake-cppcheck
    ament-cmake-cpplint
    ament-cmake-flake8
    ament-cmake-pep257
    ament-cmake-uncrustify
    builtin-interfaces
    geometry-msgs
    sensor-msgs
    tf2-eigen
    rosidl-default-generators
    rosidl-default-runtime
  ];

  doCheck = true;

  meta = {
    description = "ROS messages which correspond to the loco-3d/linear-feedback-controller package.";
    homepage = "https://github.com/loco-3d/linear-feedback-controller-msgs";
    license = lib.licenses.bsd2;
    maintainers = [ lib.maintainers.nim65s ];
    platforms = lib.platforms.linux;
  };
})
