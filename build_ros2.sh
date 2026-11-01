#!/usr/bin/env bash
set -eo pipefail
source /opt/ros/humble/setup.bash
cd "$(dirname "$0")/ros_ws"
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --build-base build-linux --install-base install-linux
source install-linux/setup.bash
set -u
