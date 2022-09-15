#!/bin/bash

#######################################################################################
# How to use:
#   1. You'll need to get your domains set up beforehand
#   2. Fill out these TODOs, but please don't publish them anywhere
#      - You need to get the foundry download link from your foundry account. 
#          It will expire after a while, so make sure you get it close to when 
#          you're ready to deploy.
#      - Again, please don't publish any of your passwords or user names anywhere
#      - Change the setup values to false if you don't want to install them
#   3. Create your droplet/instance/what have you
#   4. Run this script
#   5. Log into portainer and navigate to the stacks tab
#   6. For each service you are deploying (foundry/valheim):
#     - Click "Add stack" and give it a name
#     - Copy and paste ONE of the compose outputs into the web editor
#     - Click "Deploy the stack"
#   7. You're done. Make sure everything is working! :)
#######################################################################################
username=TODO

portainerDir=$HOME/portainer
portainerDomain=TODO

traefikDir=$HOME/traefik
traefikPass=TODO
traefikEmail=TODO
traefikDomain=TODO

setupFoundry=true
foundryDir=$HOME/foundry
foundryDownloadLink=TODO
foundryDomain=TODO

setupValheim=true
valheimDir=$HOME/valheim
valheimServer=TODO
valheimWorld=TODO
valheimPass=TODO
valheimPublic=0
valheimDomain=TODO

setupCalibre=true
calibreConfigDir=$HOME/calibre/config
calibreLibraryDir=$HOME/calibre/library
calibreDomain=TODO



#######################################################################################
# Create your user
#######################################################################################
if [ "$EUID" -eq 0 ]; then
  adduser $username
  usermod -aG sudo $username

  echo "Enter: [su - $username] and then continue the shell script as $username"
  cp "$0" "$(eval echo ~$username)"
  exit 0
fi

#######################################################################################
# Update linux
#######################################################################################
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y

#######################################################################################
# Install Docker
#######################################################################################
sudo apt update && sudo apt install apache2-utils docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
newgrp docker <<EONG
EONG

#######################################################################################
# Open ports and start firewall
#######################################################################################
sudo ufw allow 22 
sudo ufw allow 80 # Traefik
sudo ufw allow 443 # Traefik
sudo ufw allow 2456 # Valheim
sudo ufw allow 2457 # Valheim
sudo ufw allow 2458 # Valheim
sudo ufw allow 8083 # Calibre
yes | sudo ufw enable

echo “Unfortunately because of how permissions work, we have to pause here.” 
echo “Please respond to the prompt and check if you have permissions to run docker. If not, you need to log out of your account and back in, then restart the script.”
read  -n 1 -p “Have you checked docker? (y/N): ” checkedDocker

if [ “$checkedDocker” != “y” ] && [ “$checkedDocker” != “Y” ]; then
  >&2 echo “Check docker works and restart the script.”
  exit 1
fi


#######################################################################################
# Setup Traefik stack
#######################################################################################
traefikAuth=$(htpasswd -nb admin $traefikPass | sed -e "s/\\$/\\$\\$/g")
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
      - \"traefik.http.middlewares.traefik-auth.basicauth.users=$traefikAuth\"
      - \"traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https\"
      - \"traefik.http.routers.traefik-secure.entrypoints=https\"
      - \"traefik.http.routers.traefik-secure.middlewares=traefik-auth\"
      - \"traefik.http.routers.traefik-secure.rule=Host(\`$traefikDomain\`)\"
      - \"traefik.http.routers.traefik-secure.service=api@internal\"
      - \"traefik.http.routers.traefik-secure.tls.certresolver=http\"
      - \"traefik.http.routers.traefik-secure.tls=true\"
      - \"traefik.http.routers.traefik.entrypoints=http\"
      - \"traefik.http.routers.traefik.middlewares=traefik-https-redirect\"
      - \"traefik.http.routers.traefik.rule=Host(\`$traefikDomain\`)\"
networks:
  proxy:
    external: \"true\"
    " >>"$traefikDir"/docker-compose.yaml
cd $traefikDir
docker-compose up -d
cd $HOME

#######################################################################################
# Setup Portainer Stack
#######################################################################################
mkdir "$portainerDir"
mkdir "$portainerDir"/data
echo "---
version: '2'
services:
  portainer:
    image: portainer/portainer-ce:latest
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
      - \"traefik.docker.network=proxy\"
      - \"traefik.enable=true\"
      - \"traefik.http.middlewares.portainer-https-redirect.redirectscheme.scheme=https\"
      - \"traefik.http.routers.portainer-secure.entrypoints=https\"
      - \"traefik.http.routers.portainer-secure.rule=Host(\`$portainerDomain\`)\"
      - \"traefik.http.routers.portainer-secure.service=portainer\"
      - \"traefik.http.routers.portainer-secure.tls.certresolver=http\"
      - \"traefik.http.routers.portainer-secure.tls=true\"
      - \"traefik.http.routers.portainer.entrypoints=http\"
      - \"traefik.http.routers.portainer.middlewares=portainer-https-redirect\"
      - \"traefik.http.routers.portainer.rule=Host(\`$portainerDomain\`)\"
      - \"traefik.http.services.portainer.loadbalancer.server.port=9000\"
networks:
  proxy:
    external: \"true\"
    " >>"$portainerDir"/docker-compose.yaml

cd $portainerDir
docker-compose up -d
cd $HOME

#######################################################################################
# Prepare & Print FoundryVTT Compose
#######################################################################################
if $setupFoundry; then
  foundryDataDir="$foundryDir"/foundrydata
  foundryZipDir="$foundryDir"/foundrydl
  mkdir "$foundryDir"
  mkdir "$foundryDataDir"
  mkdir "$foundryZipDir"
  wget -O "$foundryZipDir"/foundryvtt.zip "$foundryDownloadLink"
  echo "****************************************************************"
  echo "Here's your FoundryVTT docker-compose stack script for Portainer:"
  echo "---
version: '2'
services:
  foundryvtt:
    image: direckthit/fvtt-docker:latest
    container_name: foundryvtt
    restart: always
    entrypoint: /opt/foundryvtt/run-server.sh
    volumes:
      - $foundryDataDir:/data/foundryvtt
      - $foundryZipDir:/host
    networks:
      - proxy
    labels:
      - \"traefik.docker.network=proxy\"
      - \"traefik.enable=true\"
      - \"traefik.http.middlewares.foundryvtt-https-redirect.redirectscheme.scheme=https\"
      - \"traefik.http.routers.foundryvtt-secure.entrypoints=https\"
      - \"traefik.http.routers.foundryvtt-secure.rule=Host(\`$foundryDomain\`)\"
      - \"traefik.http.routers.foundryvtt-secure.service=foundryvtt\"
      - \"traefik.http.routers.foundryvtt-secure.tls.certresolver=http\"
      - \"traefik.http.routers.foundryvtt-secure.tls=true\"
      - \"traefik.http.routers.foundryvtt.entrypoints=http\"
      - \"traefik.http.routers.foundryvtt.middlewares=portainer-https-redirect\"
      - \"traefik.http.routers.foundryvtt.rule=Host(\`$foundryDomain\`)\"
      - \"traefik.http.services.foundryvtt.loadbalancer.server.port=30000\"
networks:
  proxy:
    external: true"
  echo "****************************************************************"
fi

#######################################################################################
# Prepare & Print Valheim Compose
#######################################################################################
if $setupValheim; then
  mkdir "$valheimDir"
  echo "****************************************************************"
  echo "Here's your Valheim docker-compose stack script for Portainer:"
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
      - 2456-2458:2456-2458/udp
    labels:
      - \"traefik.docker.network=proxy\"
      - \"traefik.enable=true\"
      - \"traefik.http.middlewares.valheim-https-redirect.redirectscheme.scheme=https\"
      - \"traefik.http.routers.valheim-secure.entrypoints=https\"
      - \"traefik.http.routers.valheim-secure.rule=Host(\`$valheimDomain\`)\"
      - \"traefik.http.routers.valheim-secure.service=valheim\"
      - \"traefik.http.routers.valheim-secure.tls.certresolver=http\"
      - \"traefik.http.routers.valheim-secure.tls=true\"
      - \"traefik.http.routers.valheim.entrypoints=http\"
      - \"traefik.http.routers.valheim.middlewares=portainer-https-redirect\"
      - \"traefik.http.routers.valheim.rule=Host(\`$valheimDomain\`)\"
      - \"traefik.http.services.valheim.loadbalancer.server.port=2456\"
networks:
  proxy:
    external: true"
  echo "****************************************************************"
fi

#######################################################################################
# Prepare & Print Calibre Compose
#######################################################################################
if $setupCalibre; then
  mkdir "$valheimDir"
  echo "****************************************************************"
  echo "Here's your Calibre docker-compose stack script for Portainer:"
  echo "---
version: "2.1"
services:
  calibre-web:
    image: lscr.io/linuxserver/calibre-web:latest
    container_name: calibre-web
    restart: always
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - DOCKER_MODS=linuxserver/mods:universal-calibre #optional
      - OAUTHLIB_RELAX_TOKEN_SCOPE=1 #optional
    volumes:
      - $calibreConfigDir:/config
      - $calibreLibraryDir:/books
    ports:
      - 8083:8083
    networks:
      - proxy
    labels:
      - \”traefik.docker.network=proxy\”
      - \”traefik.enable=true\”
      - \”traefik.http.middlewares.calibre-web-https-redirect.redirectscheme.scheme=https\”
      - \”traefik.http.routers.calibre-web-secure.entrypoints=https\”
      - \”traefik.http.routers.calibre-web-secure.rule=Host(`$calibreDomain`)\”
      - \”traefik.http.routers.calibre-web-secure.service=calibre-web\”
      - \”traefik.http.routers.calibre-web-secure.tls.certresolver=http\”
      - \”traefik.http.routers.calibre-web-secure.tls=true\”
      - \”traefik.http.routers.calibre-web.entrypoints=http\”
      - \”traefik.http.routers.calibre-web.middlewares=portainer-https-redirect’”
      - \”traefik.http.routers.calibre-web.rule=Host(`$calibreDomain`)’”
      - \“traefik.http.services.calibre-web.loadbalancer.server.port=8083\”
networks:
  proxy:
    external: true"
  echo "****************************************************************"
fi

echo "Don't forget to set up an SSH key and your foundry options. You might also need to restart portainer."
