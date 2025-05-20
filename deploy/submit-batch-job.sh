#!/bin/bash

# Submit G1 Training Job to AWS Batch
# This script reads a YAML configuration file and submits a job to AWS Batch

set -e

# Check if yq is installed (for YAML parsing)
if ! command -v yq &> /dev/null; then
    echo "Error: yq is required but not installed."
    echo "Please install it with: pip install yq or brew install yq"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is required but not installed."
    echo "Please install it with: pip install awscli"
    exit 1
fi

# Default config file location
CONFIG_FILE="job-config.yaml"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -c|--config)
            CONFIG_FILE="$2"
            shift
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -c, --config FILE    Path to YAML configuration file (default: job-config.yaml)"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found."
    exit 1
fi

echo "Using configuration file: $CONFIG_FILE"

# Read values from YAML file
JOB_NAME=$(yq -r '.job.name' "$CONFIG_FILE")-$(date +%Y-%m-%d-%H-%M-%S)
JOB_QUEUE=$(yq -r '.job.queue' "$CONFIG_FILE")
JOB_DEFINITION=$(yq -r '.job.definition' "$CONFIG_FILE")
AWS_REGION=$(yq -r '.aws.region' "$CONFIG_FILE")
ECR_REPOSITORY=$(yq -r '.aws.ecr_repository' "$CONFIG_FILE")
IMAGE_TAG=$(yq -r '.aws.image_tag' "$CONFIG_FILE")

# Build command arguments from training parameters
COMMAND_ARGS=""
YAML_KEYS=$(yq -r '.training | keys | .[]' "$CONFIG_FILE")
for key in $YAML_KEYS; do
    value=$(yq -r ".training.$key" "$CONFIG_FILE")
    COMMAND_ARGS="${COMMAND_ARGS} --${key} ${value}"
done

# Trim leading space from command arguments
COMMAND_ARGS=$(echo "$COMMAND_ARGS" | sed -e 's/^[ \t]*//')

echo "Preparing to submit job:"
echo "  Job Name:       $JOB_NAME"
echo "  Job Queue:      $JOB_QUEUE"
echo "  Job Definition: $JOB_DEFINITION"
echo "  AWS Region:     $AWS_REGION"
echo "  Command Args:   $COMMAND_ARGS"

# Create JSON for container overrides
CONTAINER_OVERRIDES=$(cat <<EOF
{
  "command": ["python", "train.py", ${COMMAND_ARGS// /, }]
}
EOF
)

# Correct the container overrides format for AWS CLI
FORMATTED_ARGS=""
for arg in ${COMMAND_ARGS}; do
    FORMATTED_ARGS="$FORMATTED_ARGS \"$arg\","
done
FORMATTED_ARGS=${FORMATTED_ARGS%,}  # Remove trailing comma

CONTAINER_OVERRIDES="{\"command\": [\"python\", \"train.py\", $FORMATTED_ARGS]}"

# Submit job to AWS Batch
echo "Submitting job to AWS Batch..."
aws batch submit-job \
    --region "$AWS_REGION" \
    --job-name "$JOB_NAME" \
    --job-queue "$JOB_QUEUE" \
    --job-definition "$JOB_DEFINITION" \
    --container-overrides "$CONTAINER_OVERRIDES" \
    --output json

if [ $? -eq 0 ]; then
    echo "Job submitted successfully!"
else
    echo "Error submitting job. Please check your configuration and AWS credentials."
    exit 1
fi