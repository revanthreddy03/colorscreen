#!/bin/bash
SHA=$1
container_running=$(docker ps -q -f name=colorscreen_blue || docker ps -q -f name=colorscreen_green)
active_flag="blue"
old_flag=""

if [ -n "$container_running" ]; then
    # Pull new image
    docker pull "revanthreddydatla/colorscreen:$SHA"

    # Determine next port
    if grep -q "colorscreen_blue" /etc/nginx/conf.d/colorscreen.conf; then
        old_flag="blue"
        active_flag="green"
    else
        old_flag="green"
        active_flag="blue"
    fi

    # Start new container on alternate port
    docker run -d --name="colorscreen_${active_flag}" --network colorscreen-network "revanthreddydatla/colorscreen:$SHA"

    # Update Nginx config to point to new port
    sed -i "s/colorscreen_blue/colorscreen_green/" /etc/nginx/conf.d/colorscreen.conf || true
    sed -i "s/colorscreen_green/colorscreen_blue/" /etc/nginx/conf.d/colorscreen.conf || true

    # Reload Nginx without downtime
    nginx -s reload

    # Remove old container after traffic switches
    docker stop "colorscreen_${old_flag}" || true
    docker rm "colorscreen_${old_flag}" || true
else
    # First deployment
    sudo docker network create colorscreen-network
    docker run -d --name=colorscreen_blue --network colorscreen-network "revanthreddydatla/colorscreen:$SHA"
    docker run -d --name=nginx --network colorscreen-network -p 80:80 revanthreddydatla/nginx
fi