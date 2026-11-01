#!/usr/bin/env python3
"""Bounded readiness checks for the genuine ROS/Webots live pipeline.

This deliberately does not start or stop ROS, Webots, or the gateway.  The
documented launch command owns process lifecycle; this tool only waits for
authoritative readiness signals before a live test is allowed to issue a
command.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import math
import re
import subprocess
import sys
import time

import websockets


REQUIRED_NODES = {
    "/webots_bridge",
    "/localization",
    "/mapping",
    "/mission_manager",
    "/battery",
    "/global_planner",
    "/local_planner",
    "/safety_supervisor",
    "/viewer_gateway",
}
REQUIRED_TOPICS = {
    "/fabtino/bridge_status",
    "/fabtino/ground_truth/odom",
    "/fabtino/odometry/filtered",
    "/fabtino/safety_status",
    "/fabtino/scan",
    "/navigation/mission_status",
}
MIN_TOPIC_HZ = {"/fabtino/scan": 5.0, "/fabtino/odometry/filtered": 8.0}
RATE_PATTERN = re.compile(r"average rate:\s*([0-9]+(?:\.[0-9]+)?)")


def ros_lines(command: list[str], timeout: float) -> set[str]:
    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"{command[0]} failed")
    return {line.strip().split()[0] for line in result.stdout.splitlines() if line.strip()}


async def gateway_packet(url: str, timeout: float) -> dict:
    async with websockets.connect(url, open_timeout=timeout, close_timeout=timeout) as socket:
        raw = await asyncio.wait_for(socket.recv(), timeout)
        packet = json.loads(raw)
        if not isinstance(packet, dict) or packet.get("type") != "scan":
            raise RuntimeError("gateway did not provide a scan packet")
        return packet


def ready(packet: dict) -> tuple[bool, str]:
    bridge = packet.get("bridge")
    robot = packet.get("robot")
    safety = packet.get("safety")
    navigation = packet.get("navigation")
    if (not isinstance(bridge, dict) or bridge.get("connected") is not True
            or not isinstance(bridge.get("sensor_stamp_ns"), int)
            or bridge["sensor_stamp_ns"] <= 0):
        return False, "bridge is not connected"
    if not isinstance(robot, dict) or not all(
        isinstance(robot.get(k), (int, float)) and math.isfinite(robot[k])
        for k in ("x", "y", "theta")
    ):
        return False, "estimated pose is not ready"
    if not isinstance(packet.get("scanning"), bool) or not packet["scanning"]:
        return False, "LiDAR scan is not active"
    if not isinstance(safety, dict) or not safety.get("reason") or safety.get("reason") == "sensor_timeout":
        return False, "safety status is not available"
    if not isinstance(navigation, dict) or not isinstance(navigation.get("state"), str):
        return False, "navigation status is not available"
    mapping = packet.get("mapping")
    if not isinstance(mapping, dict) or mapping.get("mode") not in ("live", "known"):
        return False, "mapping is not initialized"
    grid = packet.get("map")
    if (not isinstance(grid, dict) or not isinstance(grid.get("width"), int)
            or not isinstance(grid.get("height"), int) or grid["width"] <= 0
            or grid["height"] <= 0 or not isinstance(grid.get("data_b64"), str)):
        return False, "map snapshot is not ready"
    return True, "ready"


def measured_rate(topic: str, timeout: float) -> float:
    """Read a bounded rate window from ros2 topic hz; timeout output is expected."""
    try:
        result = subprocess.run(
            ["ros2", "topic", "hz", topic, "--window", "5", "--wall-time"],
            check=False, capture_output=True, text=True, timeout=timeout,
        )
        output = (result.stdout or "") + "\n" + (result.stderr or "")
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout or ""
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        stderr = exc.stderr or ""
        if isinstance(stderr, bytes):
            stderr = stderr.decode(errors="replace")
        output += "\n" + stderr
    rates = [float(value) for value in RATE_PATTERN.findall(output)]
    if not rates:
        raise RuntimeError(f"no message rate observed on {topic} within {timeout:.1f}s")
    return rates[-1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ws-url", default="ws://127.0.0.1:8765")
    parser.add_argument("--timeout", type=float, default=30.0)
    args = parser.parse_args()
    deadline = time.monotonic() + args.timeout
    last_reason = "not checked"
    rates = {}
    while time.monotonic() < deadline:
        try:
            nodes = ros_lines(["ros2", "node", "list"], min(3.0, max(0.1, deadline - time.monotonic())))
            missing_nodes = REQUIRED_NODES - nodes
            if missing_nodes:
                last_reason = "missing ROS nodes: " + ", ".join(sorted(missing_nodes))
                time.sleep(0.25)
                continue
            topics = ros_lines(["ros2", "topic", "list"], min(3.0, max(0.1, deadline - time.monotonic())))
            missing_topics = REQUIRED_TOPICS - topics
            if missing_topics:
                last_reason = "missing ROS topics: " + ", ".join(sorted(missing_topics))
                time.sleep(0.25)
                continue
            rates = {}
            for topic, minimum in MIN_TOPIC_HZ.items():
                remaining = deadline - time.monotonic()
                if remaining <= 0.1:
                    raise RuntimeError("preflight deadline expired while checking sensor rates")
                rate = measured_rate(topic, min(4.0, remaining))
                rates[topic] = round(rate, 2)
                if rate < minimum:
                    raise RuntimeError(f"{topic} rate {rate:.2f} Hz is below {minimum:.1f} Hz")
            packet = asyncio.run(gateway_packet(args.ws_url, min(5.0, max(0.1, deadline - time.monotonic()))))
            is_ready, reason = ready(packet)
            if is_ready:
                print(json.dumps({"result": "ready", "nodes": sorted(nodes), "topics": sorted(topics), "rates_hz": rates, "packet": packet}, separators=(",", ":")))
                return 0
            last_reason = reason
        except (OSError, RuntimeError, asyncio.TimeoutError, json.JSONDecodeError, websockets.WebSocketException) as exc:
            last_reason = str(exc)
        time.sleep(0.25)
    print(json.dumps({"result": "not_ready", "reason": last_reason}), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
