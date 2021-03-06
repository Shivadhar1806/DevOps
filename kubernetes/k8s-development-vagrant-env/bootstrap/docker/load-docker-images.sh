#!/bin/bash

set -xe

# source the ubuntu global env file to make docker-engine variables available to this session
source /etc/environment

yes | sudo docker image prune -a

export IMAGE_NAME_LIST=$(sudo docker images | sed -n '1!p' | awk  '{print $1}' |  rev | cut -d '/' -f1 | rev)
export IMAGES_LIST=$(sudo docker images | sed -n '1!p' |  awk  '{print $1"_"$2}' )
export DOCKER_IMAGE_DIR=/vagrant/temp_downloaded/docker-images


mkdir -p ${DOCKER_IMAGE_DIR} || true


# Save docker images to "/vagrant/temp_downloaded/docker-images"
for image in ${IMAGES_LIST}
do

    SAVED_IMAGE_NAME=$(echo ${image} |  rev | cut -d '/' -f1 | rev )
    DOCKER_IMAGE_NAME=$(echo ${image} |  tr '_' ':' )
    if ! [ -f ${DOCKER_IMAGE_DIR}/${IMAGE_NAME}.tar ]
    then
        echo "Saving docker image ${IMAGE_NAME}"
        sudo docker save -o ${DOCKER_IMAGE_DIR}/${SAVED_IMAGE_NAME}.tar  ${DOCKER_IMAGE_NAME}  > /dev/null 2>&1
    fi
done


DOCKER_IMAGE_DIR=/vagrant/temp_downloaded/docker-images

# Load all the docker images from previously saved images "/vagrant/temp_downloaded/docker-images"
for image_tar in ${DOCKER_IMAGE_DIR}/*
do
     sudo docker load -i ${image_tar}  > /dev/null 2>&1 &
done


sleep 5

exit 0
