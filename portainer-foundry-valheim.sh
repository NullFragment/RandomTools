#!/bin/bash

# Fill all of these TODOs out!
username=TODO

portainerDir=$HOME/portainer
portainerDomain=TODO

traefikDir=$HOME/traefik
traefikPass=TODO
traefikEmail=TODO
traefikDomain=TODO

setupValheim=true #false?
valheimServer=TODO
valheimWorld=TODO
valheimPass=TODO
valheimPublic=0
valheimDir=$HOME/valheim

setupFoundry=true #false?
foundryDownloadLink=TODO

# Update
apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y

# Create a user
adduser $username
usermod -aG sudo $username
su - $username

# Install Docker
sudo apt update && sudo apt install apache2-utils docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
newgrp docker <<EONG
EONG

# Open ports
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 2456 # Valheim
sudo ufw allow 2457 # Valheim
sudo ufw allow 2458 # Valheim
sudo yes | ufw enable

mkdir "$traefikDir"
echo "api:
  dashboard: true

entryPoints:
  http:
    address: \":80\"
  https:
    address: \":443\"

providers:
  docker:
    endpoint: \"unix:///var/run/docker.sock\"
    exposedByDefault: false

certificatesResolvers:
  http:
    acme:
      email: $traefikEmail
      storage: acme.json
      httpChallenge:
        entryPoint: http" >>"$traefikDir"/traefik.yml

touch "$traefikDir"/acme.json
chmod 600 "$traefikDir"/acme.json
docker network create proxy

# Setup Portainer
mkdir "$portainerDir"
mkdir "$portainerDir"/data
echo "---
version: '2'

services:
  portainer:
    image: portainer/portainer:latest
    container_name: portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data:/data
    labels:
      - \"traefik.enable=true\"
      - \"traefik.http.routers.portainer.entrypoints=http\"
      - \"traefik.http.routers.portainer.rule=Host(\`$portainerDomain)\"
      - \"traefik.http.middlewares.portainer-https-redirect.redirectscheme.scheme=https\"
      - \"traefik.http.routers.portainer.middlewares=portainer-https-redirect\"
      - \"traefik.http.routers.portainer-secure.entrypoints=https\"
      - \"traefik.http.routers.portainer-secure.rule=Host(\`$portainerDomain\`)\"
      - \"traefik.http.routers.portainer-secure.tls=true\"
      - \"traefik.http.routers.portainer-secure.tls.certresolver=http\"
      - \"traefik.http.routers.portainer-secure.service=portainer\"
      - \"traefik.http.services.portainer.loadbalancer.server.port=9000\"
      - \"traefik.docker.network=proxy\"

networks:
  proxy:
    external: \"true\"
    " >>"$portainerDir"/docker-compose.yaml

cd $portainerDir
docker-compose up -d
cd $HOME

# Traefik Config
traefikAuth=$(htpasswd -nb admin $traefikPass | sed -e "s/\\$/\\$\\$/g")

echo "****************************************************************"
echo "Here's your traefik portainer config"
echo "---
version: '2'

services:
  traefik:
    image: traefik:v2.0
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
      - ./acme.json:/acme.json
    labels:
      - \"traefik.enable=true\"
      - \"traefik.http.routers.traefik.entrypoints=http\"
      - \"traefik.http.routers.traefik.rule=Host(\`$traefikDomain\`)\"
      - \"traefik.http.middlewares.traefik-auth.basicauth.users=$traefikAuth\"
      - \"traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https\"
      - \"traefik.http.routers.traefik.middlewares=traefik-https-redirect\"
      - \"traefik.http.routers.traefik-secure.entrypoints=https\"
      - \"traefik.http.routers.traefik-secure.rule=Host(\`$traefikDomain\`)\"
      - \"traefik.http.routers.traefik-secure.middlewares=traefik-auth\"
      - \"traefik.http.routers.traefik-secure.tls=true\"
      - \"traefik.http.routers.traefik-secure.tls.certresolver=http\"
      - \"traefik.http.routers.traefik-secure.service=api@internal\"
      "
echo "****************************************************************"

if $setupFoundry; then
  mkdir "$HOME"/foundry
  mkdir "$HOME"/foundrydata
  mkdir "$HOME"/foundrydl
  wget -O "$HOME"/foundrydl/foundryvtt.zip $foundryDownloadLink
  echo "****************************************************************"
  echo "Here's your foundry portainer config"
  echo ""
  echo "****************************************************************"
fi

if $setupValheim; then
  mkdir $valheimDir
  echo "****************************************************************"
  echo "Here's your valheim portainer config"
  echo "---
version: '2'
services:
  valheim:
    image: lloesche/valheim-server
    container_name: valheim
    restart: always
    environment:
      - SERVER_NAME=$valheimServer
      - WORLD_NAME=$valheimWorld
      - SERVER_PASS=$valheimPass
      - SERVER_PUBLIC=$valheimPublic
      - DNS_1=1.1.1.1
      - DNS_2=1.0.0.1
    volumes:
      - $valheimDir/config:/config
      - $valheimDir/data:/opt/valheim
    ports:
      - 2456-2458:2456-2458/udp"
  echo "****************************************************************"
fi

echo "Don't forget to set up an SSH key and your foundry options."
