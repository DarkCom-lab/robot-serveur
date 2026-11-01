"""Package/entrypoint consistency; this is not a ROS launch test."""
import ast
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).parents[2]


def test_launch_executables_exist_and_operation_topics_have_message_dependencies():
    source=ROOT/'ros_ws/src'
    tree=ast.parse((source/'fabtino_bringup/launch/fabtino_sim.launch.py').read_text())
    nodes=[]
    for call in ast.walk(tree):
        if isinstance(call,ast.Call) and isinstance(call.func,ast.Name) and call.func.id=='Node':
            values={item.arg:ast.literal_eval(item.value) for item in call.keywords if item.arg in ('package','executable','name')}
            nodes.append(values)
    expected={
        ('fabtino_webots_bridge','fabtino-webots-bridge','webots_bridge'),
        ('fabtino_localization','fabtino-localization','localization'),
        ('fabtino_mapping','fabtino-mapping','mapping'),
        ('fabtino_navigation','fabtino-mission-manager','mission_manager'),
        ('fabtino_navigation','fabtino-battery','battery'),
        ('fabtino_navigation','fabtino-global-planner','global_planner'),
        ('fabtino_navigation','fabtino-local-planner','local_planner'),
        ('fabtino_safety','fabtino-safety','safety_supervisor'),
        ('fabtino_viewer','fabtino-viewer-gateway','viewer_gateway'),
    }
    actual={(node['package'],node['executable'],node['name']) for node in nodes}
    assert actual==expected
    assert len(nodes)==len(actual), 'duplicate launch node definition'
    for node in nodes:
        setup=(source/node['package']/'setup.py').read_text()
        assert node['executable']+' = ' in setup
    for package in ('fabtino_localization','fabtino_mapping','fabtino_viewer','fabtino_webots_bridge'):
        manifest=ET.parse(source/package/'package.xml').getroot()
        assert 'std_msgs' in [item.text for item in manifest.findall('depend')]
