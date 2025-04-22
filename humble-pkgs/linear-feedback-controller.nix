{
  lib,
  stdenv,

  fetchFromGitHub,

  # nativeBuildInputs
  cmake,
  fmt,
  python3Packages,
  ament-cmake,
  ament-cmake-auto,
  eigen3-cmake-module,
  generate-parameter-library-py,
  pluginlib,
  rosidl-default-generators,

  # propagatedBuildInputs
  linear-feedback-controller-msgs,
  control-toolbox,
  controller-interface,
  nav-msgs,
  pal-statistics,
  parameter-traits,
  realtime-tools,
  rclcpp-lifecycle,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "linear-feedback-controller";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "loco-3d";
    repo = "linear-feedback-controller";
    tag = "v${finalAttrs.version}";
    hash = "sha256-iolp/25VccP7knwRUOj4eQ5kGlcvWEiCfTYHkx/AUrA=";
  };

  nativeBuildInputs = [
    cmake
    fmt
    python3Packages.python
    ament-cmake
    ament-cmake-auto
    eigen3-cmake-module # this is a mistake on humble
    generate-parameter-library-py
    pluginlib
    rosidl-default-generators
  ];

  propagatedBuildInputs = [
    fmt
    linear-feedback-controller-msgs
    python3Packages.pinocchio
    python3Packages.example-robot-data
    control-toolbox
    controller-interface
    nav-msgs
    pal-statistics
    parameter-traits
    realtime-tools
    rclcpp-lifecycle
  ];

  doCheck = true;

  # generate_parameter_library_markdown complains that build/doc exists
  # ref. https://github.com/PickNikRobotics/generate_parameter_library/pull/212
  enableParallelBuilding = false;

  meta = {
    description = "ROS2 control linear feedback controller. It connects Ricatti gains based controllers with the hardware through ROS2 topics.";
    homepage = "https://github.com/loco-3d/linear-feedback-controller";
    license = lib.licenses.bsd2;
    maintainers = [ lib.maintainers.nim65s ];
    platforms = lib.platforms.linux;
  };
})
