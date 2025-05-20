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
import torch
import time



def main():
    scene_cfg = G1RoughEnvCfg()
    env = ManagerBasedRLEnv(scene_cfg)
    agent_cfg: RslRlOnPolicyRunnerCfg = unitree_g1_agent_cfg
    env = RslRlVecEnvWrapper(env)
    ppo_runner = OnPolicyRunner(
        env, agent_cfg, log_dir=None, device=agent_cfg['device']
    )
    policy = ppo_runner.get_inference_policy(device=env.unwrapped.device)

    print("[INFO]: Setup complete...")

    obs, _ = env.get_observations()

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
