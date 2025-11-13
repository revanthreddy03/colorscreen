#!/bin/bash
SHA=$1
container_running=$(docker ps -q -f name=colorscreen_blue)
if [ -z "$container_running" ]; then
    container_running=$(docker ps -q -f name=colorscreen_green)
fi

echo "is container_running: $container_running"
active_flag=""
old_flag=""

if [ -n "$container_running" ]; then
    # Pull new image
    docker pull "revanthreddydatla/colorscreen:$SHA"

    blue_container_running=$(docker ps -q -f name=colorscreen_blue)

    # Determine next port
    if [ -n "$blue_container_running" ]; then
        echo "blue_container_running: $blue_container_running"
        old_flag="blue"
        new_flag="green"
    else
        old_flag="green"
        new_flag="blue"
    fi

    # Start new container on alternate port
    docker run -d --name="colorscreen_${new_flag}" --network colorscreen-network "revanthreddydatla/colorscreen:$SHA"

    # Update Nginx config to point to new port
    if [ $new_flag == "blue" ]; then
        docker exec nginx sed -i "s/colorscreen_green/colorscreen_blue/" /etc/nginx/nginx.conf || true
    else
        docker exec nginx sed -i "s/colorscreen_blue/colorscreen_green/" /etc/nginx/nginx.conf || true
    fi

    # Reload Nginx without downtime
    docker exec nginx nginx -s reload

    # Remove old container after traffic switches
    docker stop "colorscreen_${old_flag}" || true
    docker rm "colorscreen_${old_flag}" || true
else
    # First deployment
    docker network create colorscreen-network || true
    docker run -d --name=colorscreen_blue --network colorscreen-network "revanthreddydatla/colorscreen:$SHA"
    docker run -d --name=nginx --network colorscreen-network -p 80:80 revanthreddydatla/nginx
fi