FROM nvcr.io/nvidia/isaac-lab:2.1.0


WORKDIR /app


COPY resources resources
COPY cli_args.py .
COPY agent_cfg.py .
COPY managed_g1.py .
COPY train.py .

ENTRYPOINT ["python", "train.py", "--task", "G1-Walking-v0", "--num_envs", "2"]
