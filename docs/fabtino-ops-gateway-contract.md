# Fabtino Ops gateway contract — current implementation

Status: baseline contract captured from source before recovery changes.

This document describes what the checked-in gateway currently does. It does
not describe the target recovery protocol. Missing behavior is listed as a
gap instead of being inferred.

## Implementation

- Source: `ros_ws/src/fabtino_viewer/fabtino_viewer/viewer_gateway.py`
- Launch: `ros_ws/src/fabtino_bringup/launch/fabtino_sim.launch.py`
- Browser transport: WebSocket, bound by default to `127.0.0.1:8765`.
- Browser must not connect to the Webots/controller TCP bridge on port 8766.
- There is no URL path, server welcome, client hello, protocol-version check,
  authentication, origin allow-list, or application heartbeat in the current
  implementation. The default loopback bind prevents this unauthenticated
  development endpoint from listening on non-local interfaces. Do not override
  the host to expose it remotely until those controls are implemented.
- `websockets.serve` accepts multiple clients and broadcasts the same packet
  to every connected client. There is no explicit per-client authorization or
  request serialization layer.

## Server-to-browser packet

The gateway broadcasts a JSON object approximately every 100 ms while at least
one client is connected. The top-level `type` is always `scan` in the current
implementation.

| Field | Current source-backed meaning |
|---|---|
| `type` | `scan` |
| `scanning` | Whether a scan message is present and scan acquisition is enabled |
| `points_frame` | Literal `map` |
| `new_points` | Array of finite `[x,y,z]` points decoded from `/fabtino/pointcloud`; emitted when a new cloud arrives |
| `live_points` | Array of finite `[x,y,z]` points from `/fabtino/live_pointcloud` when its stamp is less than 0.5 s old |
| `robot` | Estimated pose from `/fabtino/odometry/filtered`: `{x,y,theta}`; `theta` is radians |
| `ground_truth` | Diagnostic pose from `/fabtino/ground_truth/odom`, only when estimated pose exists |
| `estimation_error` | Diagnostic position/yaw difference between ground truth and estimate |
| `navigation` | JSON decoded from `/navigation/mission_status` or `{}` |
| `safety` | JSON decoded from `/fabtino/safety_status` or `{}` |
| `battery` | JSON decoded from `/fabtino/battery` or omitted when unavailable |
| `operation` | Gateway operation state, such as `pending`, `complete`, or `error` |
| `mapping` | JSON decoded from `/fabtino/mapping_status` or `{}` |
| `bridge` | JSON decoded from `/fabtino/bridge_status` or `{}` |
| `scan_matching` | Gateway localization/import status or `{}` |
| `navigation_config` | JSON decoded from `/navigation/config` or `null` |

The packet has no documented source timestamp or sequence number. Socket-open
and telemetry-fresh are not separate protocol states. The frontend must not
interpret a missing optional field as a zero value.

### Map object

When a current `nav_msgs/OccupancyGrid` is available, the packet may contain:

```json
{
  "resolution": 0.1,
  "radius": 20.0,
  "width": 400,
  "height": 400,
  "data_b64": "...",
  "map_id": "..."
}
```

The source serializes the signed int8 occupancy array in row-major order using
base64. The current browser object does not include `frame_id`, origin x/y,
origin yaw, an explicit occupancy convention, a map revision, or a source
timestamp. `radius` is derived from the negative x component of the ROS map
origin and is not a complete map transform. REAL map-coordinate interaction
must remain disabled until complete metadata is exposed and tested.

## Browser-to-gateway commands

Incoming messages are parsed as JSON and dispatched by their top-level `type`.
The current gateway does not reject unknown command names with a structured
success/failure response; an unrecognized type simply has no command effect.

| Type | Payload fields read by gateway | Backend action | Current result behavior |
|---|---|---|---|
| `drive` | `v`, `omega` | Publishes finite, clamped `TwistStamped` to `/teleop/cmd_vel`; limits are ±0.5 m/s and ±1.5 rad/s | No success result |
| `stop` | none | Publishes navigation stop plus zero `TwistStamped` | No success result |
| `nav_goal` | `x`, `y`, `yaw_deg` | Publishes `{type: goal, x, y, yaw_deg}` to `/navigation/request` | Navigation status is later broadcast; no immediate ack |
| `nav_explore` | none | Publishes `{type: explore}` to `/navigation/request` | No immediate ack |
| `nav_stop` | none | Publishes `{type: stop, x:null, y:null, yaw_deg:null}` to `/navigation/request` | No immediate ack |
| `delivery_start` | Payload forwarded | Publishes `{type: delivery_start, ...}` to `/navigation/request` | No immediate ack |
| `delivery_return` | Payload forwarded | Publishes `{type: delivery_return, ...}` to `/navigation/request` | No immediate ack |
| `set_navigation_config` | Payload validated by `validate_config` | Publishes `{type: configure, ...}` to `/navigation/request` | Config status is later broadcast; no immediate ack |
| `clear_map` | `request_id` plus operation payload | Publishes operation to `/viewer/request`; stops first and waits for node statuses | Pending/complete/error appears in `operation` |
| `reset_odom` | `request_id` plus operation payload | Same operation path; also invalidates older odometry | Pending/complete/error appears in `operation` |
| `nav_map` | `request_id`, imported grid, optional config | Validates/imports map and publishes operation | Pending/complete/error appears in `operation` |
| `nav_clear_map` | Operation payload | Publishes operation to `/viewer/request` | Pending/complete/error appears in `operation` |
| `configure_map` | `request_id` plus map dimensions | Validates dimensions and publishes operation | Pending/complete/error appears in `operation` |
| `toggle_scan` / `set_scan` | optional `enabled` | Publishes `/fabtino/scan_enable` | No success result |
| `set_battery` | `soc_pct`, optional `request_id` | Simulator-only `/battery/request` operation after safety checks | No immediate ack |

For operation commands, generated request IDs are UUIDs if absent and IDs are
limited to 128 characters. A newer map/reset operation cancels the previous
one. Operation status is correlated by `request_id` and required node status.
The gateway emits `command_result` only when JSON parsing or command handling
raises an exception, with `state: error`, the incoming request ID when
available, and a text `reason`.

## Safety and unsupported semantics

- Motion is routed through `/teleop/cmd_vel` and the ROS safety supervisor;
  browser code must not connect to TCP 8766 or publish a raw controller packet.
- The gateway clamps drive values but current protocol behavior does not define
  a command lease, dead-man timeout, duplicate request policy, or reconnect
  replay policy.
- The source contains no pause, resume, skip, retry, queue reorder, or mission
  CRUD command at the WebSocket gateway. Those UI actions must be disabled or
  explicitly marked local-only until a backend command is added and tested.
- Zone configuration is validated by the backend's named circular-zone schema;
  the frontend's rectangular overlays are not wire-compatible.

## Recovery changes required before REAL mode

The following are intentionally not claimed by this baseline contract:

1. Welcome/snapshot and protocol version negotiation.
2. Origin/authentication policy appropriate to deployment.
3. Heartbeat, telemetry timestamps, sequence numbers, and stale semantics.
4. Acknowledgement/result lifecycle for every state-changing command.
5. Bounded request-ID deduplication and safe retry behavior.
6. Reconnect snapshot and map/state revisions.
7. Complete map origin pose, frame, occupancy convention, and revision metadata.

REAL-mode controls remain blocked until these gaps are implemented and covered
by gateway tests.
