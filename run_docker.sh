#!/usr/bin/env bash

# Check args
if [ "$#" -lt 1 ]; then
  echo "usage: ./run.sh IMAGE_NAME"
  return 1
fi

set -e

IMAGE_NAME=$1 && shift 1

THIS_HOST=`hostname`
NVIDIA_DOCKER_VERSION=$(dpkg -l | grep nvidia-docker | awk '{ print $3 }' | awk -F'[_.]' '{print $1}')

# Determine the appropriate version of the docker run command
    docker_run_cmd="sudo docker run "
#if [ $NVIDIA_DOCKER_VERSION = "1" ]; then
#    docker_run_cmd="nvidia-docker run --rm"
#elif [ $NVIDIA_DOCKER_VERSION = "2" ]; then
#  docker_run_cmd="docker run --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=0 --rm"
#else
#  echo "[Warning] nvidia-docker not installed, running docker without Nvidia hardware acceleration / OpenGL support"
#  docker_run_cmd="docker run --rm"
#fi

# Deterimine configured user for the docker image
docker_user=$(sudo docker image inspect --format '{{.Config.User}}' $IMAGE_NAME)
if [ "$docker_user" = "" ]; then
    dHOME_FOLDER="/root"
else
    dHOME_FOLDER="/home/$docker_user"    
fi
xhost +local:root
# Run the container with NVIDIA Graphics acceleration, shared network interface, shared hostname, shared X11
$(echo $docker_run_cmd) \
    --gpus all \
    --cpus=0.0 \
    --net=host \
    --ipc=host \
    --privileged \
    --rm \
    -p 8889:8889 \
    -p 22022:22 \
    -e DISPLAY=$DISPLAY \
    -e ROS_HOSTNAME=$THIS_HOST \
    -e XAUTHORITY=$dHOME_FOLDER/.Xauthority \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $HOME/.Xauthority:$dHOME_FOLDER/.Xauthority \
    -v $HOME:/mnt \
    -v $HOME/notebooks:/notebooks \
    -it $IMAGE_NAME "$@"
