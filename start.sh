#!/bin/bash


IMAGE="transformers-pytorch-gpu:v0.1"
WORKDIR="/workspace"


function PrintHelpingMessage() {
    echo -e "Usage:"
    echo -e "  * Display helping message: $0 --help"
    echo -e "  * Run JupyterLab         : $0 --notebook"
    echo -e "  * Run TensorBoard        : $0 --tensorboard [logdir]"
    echo -e ""
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            PrintHelpingMessage
            exit 0 ;;

        --notebook|-n)
            export COMMAND="notebook"
            export CONTAINER="Transformers" ;;

        --tensorboard|-t)
            export COMMAND="tensorboard"
            export CONTAINER="TensorBoard"
            export LOGDIR=$2

            if [[ "$LOGDIR" == "" ]]; then
               PrintHelpingMessage
               exit 1
            fi

            shift ;;

        *) 
            PrintHelpingMessage
            exit 1 ;;
    esac
shift
done


# check if the container is running
HASH_RUNNING=`docker ps -q -f name=$CONTAINER`

# check if the container is stopped
HASH_STOPPED=`docker ps -qa -f name=$CONTAINER`


if [[ -n "$HASH_RUNNING" ]]; then
    echo -e "Existing RUNNING container $CONTAINER found, proceed to exec another shell"
    docker exec -ti $HASH_RUNNING /bin/bash

elif [[ -n "$HASH_STOPPED" ]]; then
    echo -e "Existing STOPPED container $CONTAINER found, proceed to start"
    docker start --attach -i $HASH_STOPPED

elif [[ $COMMAND == "notebook" ]]; then
    docker run \
        --name $CONTAINER \
        --gpus all \
        --env DATADIR=$WORKDIR/data \
        --env LOGDIR=$WORKDIR/logs \
        -d \
        -ti \
        -v ${PWD}/projects:$WORKDIR/projects \
        -v ${PWD}/logs:$WORKDIR/logs \
        -v /hdd/data/nlp:$WORKDIR/data \
        -p 8888:8888 \
        $IMAGE \
        jupyter lab --no-browser --ip=0.0.0.0 --allow-root

elif [[ $COMMAND == "tensorboard" ]]; then
    docker run \
        --name $CONTAINER \
        -d \
        -v ${PWD}/logs:$WORKDIR/logs \
        -p 6006:6006 \
        -p 6007:6007 \
        -p 6008:6008 \
        $IMAGE \
        tensorboard --logdir=$WORKDIR/logs/$LOGDIR/pl_logs --host=0.0.0.0
fi
