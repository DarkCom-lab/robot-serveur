import math
import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "ros_ws" / "src" / "fabtino_core"))
sys.path.insert(0, str(Path(__file__).parents[1] / "ros_ws" / "src" / "fabtino_mapping"))
import rclpy
from sensor_msgs.msg import LaserScan

from fabtino_mapping.mapping_node import MappingNode
from fabtino_core.navigation.planner import OccupancyGrid
from fabtino_core.static_points import StaticPointFilter


class _Logger:
    def debug(self, message):
        pass

    def warning(self, message):
        pass


class _Publisher:
    def __init__(self):
        self.messages = []

    def publish(self, message):
        self.messages.append(message)


def _bare_mapping_node():
    node = object.__new__(MappingNode)
    node.pose_match_tolerance_s = 0.05
    node.scan_queue = deque(maxlen=8)
    node.pose_history = deque(maxlen=8)
    node.next_scan_sequence = 0
    node.pose = (0.0, 0.0, 0.0)
    node.grid = OccupancyGrid(0.1, 5.0)
    node.revision = 0
    node.lidar_angle_sign = -1.0
    node.lidar_subsample = 1
    node.last_map_publish_time = 0.0
    node.map_publish_period_s = 0.5
    node.pub_points = _Publisher()
    node.pub_live_points=_Publisher()
    node.mode='live';node.dynamic_cells={};node.static_filter=StaticPointFilter(.1)
    node.free_clear_observations=3;node.free_observations={};node.latest_integrated_scan_ns=0
    node.pub_map = _Publisher()
    node.pub_local = _Publisher()
    node.pub_status = _Publisher()
    node.get_logger = lambda: _Logger()
    node.publish_grid = lambda *args: None
    node.publish_local = lambda: None
    return node


def _scan(timestamp, distance=2.0):
    msg = LaserScan()
    msg.header.stamp.sec = int(timestamp)
    msg.header.stamp.nanosec = int(round((timestamp - int(timestamp)) * 1e9))
    msg.angle_min = 0.0
    msg.angle_increment = 0.0
    msg.range_min = 0.1
    msg.range_max = 10.0
    msg.ranges = [distance]
    msg.intensities = []
    return msg


def test_one_scan_is_integrated_once_even_when_update_runs_twice():
    node = _bare_mapping_node()
    node.pose_history.append((1.0, 0.0, 0.0, 0.0))
    node.scan_queue.append((1, _scan(1.0)))

    node.update()
    first_grid = node.grid.data.copy()
    first_cloud_count = len(node.pub_points.messages)
    node.update()

    assert node.grid.revision == 1  # no grid mutation is expected for one fresh unconfirmed hit
    assert (node.grid.data == first_grid).all()
    assert len(node.pub_points.messages) == first_cloud_count == 1


def test_scan_pose_is_interpolated_at_scan_timestamp():
    node = _bare_mapping_node()
    node.pose_history.extend([
        (1.0, 0.0, 0.0, 0.0),
        (1.04, 2.0, 0.0, math.pi),
    ])
    pose, source = node.pose_for_scan(1.02)

    assert source == 'interpolated_pose'
    assert math.isclose(pose[0], 1.0, abs_tol=1e-12)
    assert math.isclose(pose[1], 0.0, abs_tol=1e-12)
    assert math.isclose(abs(pose[2]), math.pi / 2, abs_tol=1e-12)


def test_unmasked_no_return_ray_clears_learned_cell_without_endpoint():
    node = _bare_mapping_node()
    obstacle = node.grid.cell(1.0, 0.0)
    node.grid.set_cell(obstacle, 100)
    for seq in range(3):
        timestamp = 1.0 + seq * .1
        node.pose_history.append((timestamp, 0.0, 0.0, 0.0))
        scan = _scan(timestamp, math.inf)
        scan.range_max = 3.0
        scan.intensities = [1.0]
        node.scan_queue.append((seq + 1, scan))
        node.update()

    endpoint = node.grid.cell(3.0, 0.0)
    assert node.grid.data[obstacle[1], obstacle[0]] == 0
    assert endpoint is not None and node.grid.data[endpoint[1], endpoint[0]] != 100


def test_repeated_unmasked_no_return_marks_initially_unknown_ray_as_free():
    node = _bare_mapping_node()
    known_free = node.grid.cell(1.0, 0.0)
    assert known_free is not None and node.grid.data[known_free[1], known_free[0]] == -1
    for seq in range(3):
        timestamp = 1.0 + seq * .1
        node.pose_history.append((timestamp, 0.0, 0.0, 0.0))
        scan = _scan(timestamp, math.inf)
        scan.range_max = 3.0
        scan.intensities = [1.0]
        node.scan_queue.append((seq + 1, scan))
        node.update()

    assert node.grid.data[known_free[1], known_free[0]] == 0


def test_confirmed_scan_obstacle_survives_robot_moving_away_and_free_ray():
    node = _bare_mapping_node()
    for seq in range(32):
        timestamp = 1.0 + seq * .1
        node.pose_history.append((timestamp, 0.0, 0.0, 0.0))
        node.scan_queue.append((seq + 1, _scan(timestamp, 1.0)))
        node.update()

    obstacle = node.grid.cell(1.0, 0.0)
    assert obstacle is not None
    assert node.grid.data[obstacle[1], obstacle[0]] == 100
    assert node.grid.static_data[obstacle[1], obstacle[0]] == 100

    timestamp = 4.2
    node.pose_history.append((timestamp, 0.5, 0.0, 0.0))
    clear_ray = _scan(timestamp, math.inf)
    clear_ray.range_max = 3.0
    clear_ray.intensities = [1.0]
    node.scan_queue.append((33, clear_ray))
    node.update()

    assert node.grid.data[obstacle[1], obstacle[0]] == 100


def test_masked_no_return_ray_does_not_clear_map():
    node = _bare_mapping_node()
    node.pose_history.append((1.0, 0.0, 0.0, 0.0))
    obstacle = node.grid.cell(1.0, 0.0)
    node.grid.set_cell(obstacle, 100)
    scan = _scan(1.0, math.inf)
    scan.range_max = 3.0
    scan.intensities = [0.0]

    node.scan_queue.append((1, scan))
    node.update()

    assert node.grid.data[obstacle[1], obstacle[0]] == 100


def test_known_map_geometry_is_not_cleared_by_no_return():
    node = _bare_mapping_node()
    node.mode = 'known'
    node.pose_history.append((1.0, 0.0, 0.0, 0.0))
    obstacle = node.grid.cell(1.0, 0.0)
    node.grid.set_cell(obstacle, 100)
    scan = _scan(1.0, math.inf)
    scan.range_max = 3.0
    scan.intensities = [1.0]
    node.scan_queue.append((1, scan))
    node.update()
    assert node.grid.data[obstacle[1], obstacle[0]] == 100


def test_exact_max_range_is_free_ray_not_occupied_endpoint():
    node = _bare_mapping_node()
    node.pose_history.append((1.0, 0.0, 0.0, 0.0))
    scan = _scan(1.0, 3.0)
    scan.range_max = 3.0
    scan.intensities = [1.0]

    node.scan_queue.append((1, scan))
    node.update()

    endpoint = node.grid.cell(3.0, 0.0)
    assert endpoint is not None and node.grid.data[endpoint[1], endpoint[0]] != 100


def test_unsampled_thin_return_is_retained_in_navigation_layer():
    node = _bare_mapping_node()
    node.lidar_subsample = 8
    node.pose_history.append((1.0, 0.0, 0.0, 0.0))
    scan = _scan(1.0)
    scan.angle_min = -math.pi
    scan.angle_increment = 2 * math.pi / 1024
    scan.range_max = 12.0
    scan.ranges = [math.inf] * 1024
    scan.ranges[1] = 2.0
    scan.intensities = [1.0] * 1024

    node.scan_queue.append((1, scan))
    node.update()

    angle = scan.angle_min + scan.angle_increment
    from fabtino_core.localization.frames import lidar_polar_to_robot, robot_to_world_point
    endpoint_xy = robot_to_world_point((0.0, 0.0, 0.0), lidar_polar_to_robot(2.0, angle, -1.0))
    cell = node.grid.cell(*endpoint_xy)
    assert cell is not None
    assert node.dynamic_cells[cell] == 1_000_000_000
