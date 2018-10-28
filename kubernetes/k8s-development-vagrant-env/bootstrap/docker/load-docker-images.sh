#!/bin/bash

set -xe

# source the ubuntu global env file to make docker-engine variables available to this session
source /etc/environment

IMAGE_NAME_LIST=$(docker images | sed -n '1!p' | awk  '{print $1}' |  rev | cut -d '/' -f1 | rev)
IMAGES_LIST=$(docker images | sed -n '1!p' | awk  '{print $1}' )
DOCKER_IMAGE_DIR=/vagrant/temp_downloaded/docker-images

mkdir -p ${DOCKER_IMAGE_DIR}


# Save docker images to "/vagrant/temp_downloaded/docker-images"
for image in ${IMAGES_LIST}
do

    IMAGE_NAME=$(echo ${image} |  rev | cut -d '/' -f1 | rev )
    if ! [ -f ${DOCKER_IMAGE_DIR}/${IMAGE_NAME}.tar ]
    then
        echo "Saving docker image ${IMAGE_NAME}"
        docker save -o ${DOCKER_IMAGE_DIR}/${IMAGE_NAME}.tar  ${image}  > /dev/null 2>&1 &
    fi
done


DOCKER_IMAGE_DIR=/vagrant/temp_downloaded/docker-images

# Load all the docker images from previously saved images "/vagrant/temp_downloaded/docker-images"
for image_tar in ${DOCKER_IMAGE_DIR}/*
do
     docker load -i ${image_tar}  > /dev/null 2>&1 &
done

sleep 60

exit 0