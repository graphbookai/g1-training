import argparse
from isaaclab.app import AppLauncher

# add argparse arguments
parser = argparse.ArgumentParser(
    description="Tutorial on using the interactive scene interface."
)
parser.add_argument(
    "--num_envs", type=int, default=2, help="Number of environments to spawn."
)
# append AppLauncher cli args
AppLauncher.add_app_launcher_args(parser)
# parse the arguments
args_cli = parser.parse_args()

# launch omniverse app
app_launcher = AppLauncher()
simulation_app = app_launcher.app

import managed_g1
from managed_g1 import G1RoughEnvCfg
from isaaclab.envs import ManagerBasedRLEnv
from rsl_rl.runners import OnPolicyRunner
from agent_cfg import UnitreeG1RoughRunnerCfg, unitree_g1_agent_cfg
from isaaclab_rl.rsl_rl import RslRlOnPolicyRunnerCfg, RslRlVecEnvWrapper
import threading
import omni.appwindow
import rclpy

# from ros2 import RobotBaseNode, add_camera, add_rtx_lidar, pub_robo_data_ros2
from geometry_msgs.msg import Twist
import torch, carb
import time


def sub_keyboard_event(event, *args, **kwargs) -> bool:

    if len(managed_g1.base_command) > 0:
        if event.type == carb.input.KeyboardEventType.KEY_PRESS:
            if event.input.name == "W":
                managed_g1.base_command["0"] = [1, 0, 0]
            if event.input.name == "S":
                managed_g1.base_command["0"] = [-1, 0, 0]
            if event.input.name == "A":
                managed_g1.base_command["0"] = [0, 1, 0]
            if event.input.name == "D":
                managed_g1.base_command["0"] = [0, -1, 0]
            if event.input.name == "Q":
                managed_g1.base_command["0"] = [0, 0, 1]
            if event.input.name == "E":
                managed_g1.base_command["0"] = [0, 0, -1]

            if len(managed_g1.base_command) > 1:
                if event.input.name == "I":
                    managed_g1.base_command["1"] = [1, 0, 0]
                if event.input.name == "K":
                    managed_g1.base_command["1"] = [-1, 0, 0]
                if event.input.name == "J":
                    managed_g1.base_command["1"] = [0, 1, 0]
                if event.input.name == "L":
                    managed_g1.base_command["1"] = [0, -1, 0]
                if event.input.name == "U":
                    managed_g1.base_command["1"] = [0, 0, 1]
                if event.input.name == "O":
                    managed_g1.base_command["1"] = [0, 0, -1]
        elif event.type == carb.input.KeyboardEventType.KEY_RELEASE:
            for i in range(len(managed_g1.base_command)):
                managed_g1.base_command[str(i)] = [0, 0, 0]
    return True


def cmd_vel_cb(msg, num_robot):
    x = msg.linear.x
    y = msg.linear.y
    z = msg.angular.z
    managed_g1.base_command[str(num_robot)] = [x, y, z]


def add_cmd_sub(num_envs):
    node_test = rclpy.create_node("position_velocity_publisher")
    for i in range(num_envs):
        node_test.create_subscription(
            Twist, f"robot{i}/cmd_vel", lambda msg, i=i: cmd_vel_cb(msg, str(i)), 10
        )
    # Spin in a separate thread
    thread = threading.Thread(target=rclpy.spin, args=(node_test,), daemon=True)
    thread.start()


def main():
    _input = carb.input.acquire_input_interface()
    _appwindow = omni.appwindow.get_default_app_window()
    _keyboard = _appwindow.get_keyboard()
    _sub_keyboard = _input.subscribe_to_keyboard_events(_keyboard, sub_keyboard_event)

    scene_cfg = G1RoughEnvCfg()
    env = ManagerBasedRLEnv(scene_cfg)
    agent_cfg: RslRlOnPolicyRunnerCfg = unitree_g1_agent_cfg
    env = RslRlVecEnvWrapper(env)
    ppo_runner = OnPolicyRunner(
        env, agent_cfg, log_dir=None, device=agent_cfg['device']
    )
    ppo_runner.load("g1_training/logs/model_2050.pt")
    policy = ppo_runner.get_inference_policy(device=env.unwrapped.device)

    print("[INFO]: Setup complete...")

    obs, _ = env.get_observations()

    # initialize ROS2 node
    rclpy.init()
    # base_node = RobotBaseNode(scene_cfg.scene.num_envs)
    add_cmd_sub(scene_cfg.scene.num_envs)

    # annotator_lst = add_rtx_lidar(scene_cfg.scene.num_envs, args_cli.robot, False)
    # start_time = time.time()
    while simulation_app.is_running():
        with torch.inference_mode():
            actions = policy(obs)
            # actions = torch.tensor([[
            #     0., 0., 0., 0., 0., 0., 0., 0.,
            #     0., 0., 0., 0., 0., 0., 0., 0.,
            #     0., 0., 0., 0., 0., 0., 0., 0.,
            #     0., 0., 0., 0., 0., 0., 0., 0.,
            #     0., 0., 0., 0., 0.]])
            # print(actions)
            obs, _, _, _ = env.step(actions)
            # pub_robo_data_ros2(args_cli.robot, scene_cfg.scene.num_envs, base_node, env, annotator_lst, start_time)


if __name__ == "__main__":
    main()
    simulation_app.close()
