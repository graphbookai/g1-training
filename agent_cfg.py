from isaaclab.utils import configclass

from isaaclab_rl.rsl_rl import RslRlOnPolicyRunnerCfg, RslRlPpoActorCriticCfg, RslRlPpoAlgorithmCfg
from isaaclab_rl.rsl_rl.rl_cfg import RslRlOnPolicyRunnerCfg

@configclass
class UnitreeG1RoughRunnerCfg(RslRlOnPolicyRunnerCfg):
    """Configuration for Unitree G1 Rough environment."""
    device = "cuda"
    seed = 42
    
    # Environment settings
    num_steps_per_env = 24
    max_iterations = 15000
    save_interval = 50
    experiment_name = "g1_rough"
    empirical_normalization = False

    # Policy settings
    policy = RslRlPpoActorCriticCfg(
        init_noise_std=1.0,
        actor_hidden_dims=[512, 256, 128],
        critic_hidden_dims=[512, 256, 128],
        activation="elu",
    )

    # Algorithm settings
    algorithm = RslRlPpoAlgorithmCfg(
        value_loss_coef=1.0,
        use_clipped_value_loss=True,
        clip_param=0.2,
        entropy_coef=0.01,
        num_learning_epochs=5,
        num_mini_batches=4,
        learning_rate=0.001,
        schedule="adaptive",
        gamma=0.99,
        lam=0.95,
        desired_kl=0.01,
        max_grad_norm=1.0,
    )
    # Logging settings
    logger = "tensorboard"
    neptune_project = "orbit"
    wandb_project = "orbit"
    run_name = ""
    resume = False
    load_run = ".*"
    load_checkpoint = "logs/model_.*.pt"

    # Additional settings can be added here as needed
    
unitree_g1_agent_cfg = {
    "seed": 42,
    "device": "cuda",
    "num_steps_per_env": 24,
    "max_iterations": 15000,
    "empirical_normalization": False,
    "policy": {
        "class_name": "ActorCritic",
        "init_noise_std": 1.0,
        "actor_hidden_dims": [512, 256, 128],
        "critic_hidden_dims": [512, 256, 128],
        "activation": "elu",
    },
    "algorithm": {
        "class_name": "PPO",
        "value_loss_coef": 1.0,
        "use_clipped_value_loss": True,
        "clip_param": 0.2,
        "entropy_coef": 0.01,
        "num_learning_epochs": 5,
        "num_mini_batches": 4,
        "learning_rate": 0.001,
        "schedule": "adaptive",
        "gamma": 0.99,
        "lam": 0.95,
        "desired_kl": 0.01,
        "max_grad_norm": 1.0,
    },
    "save_interval": 50,
    "experiment_name": "g1_rough",
    "run_name": "",
    "logger": "tensorboard",
    "neptune_project": "orbit",
    "wandb_project": "orbit",
    "resume": False,
    "load_run": ".*",
    "load_checkpoint": "model_.*.pt",
}