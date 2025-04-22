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
    eigen3-cmake-module
    generate-parameter-library-py
    pluginlib
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

  # revert https://github.com/lopsided98/nix-ros-overlay/blob/develop/distros/rosidl-generator-py-setup-hook.sh
  # as they break tests
  postConfigure = ''
    cmake $cmakeDir -DCMAKE_SKIP_BUILD_RPATH:BOOL=OFF
  '';

  doCheck = true;

  # some dependency started to leak qtPreHook
  dontWrapQtApps = true;

  meta = {
    description = "ROS2 control linear feedback controller. It connects Ricatti gains based controllers with the hardware through ROS2 topics.";
    homepage = "https://github.com/loco-3d/linear-feedback-controller";
    license = lib.licenses.bsd2;
    maintainers = [ lib.maintainers.nim65s ];
    platforms = lib.platforms.linux;
  };
})
