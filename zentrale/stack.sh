#!/bin/bash

# Error handling
set -o errexit          # Exit on most errors
set -o errtrace         # Make sure any error trap is inherited
set -o pipefail         # Use last non-zero exit code in a pipeline
#set -o nounset          # Exits if any of the variables is not set

GRN='\033[0;32m' && YEL='\033[1;33m' && RED='\033[0;31m' && BLU='\033[0;34m' && NC='\033[0m'

#folder where the current script is located
declare HOME="$(cd "$(dirname "$0")"; pwd -P)"
declare env=".env"
declare users=".auth/users.txt"
declare adminuser="boss"

createnet() {
  if [ ! "$(docker network ls | grep proxy)" ]; then
    printf "\ncreatenet(): Creating docker network (${YEL}proxy${NC}). \n"
    sudo docker network create proxy
  fi
}

createsecrets() {
  printf "\ncreatesecrets(): Started...\n"
  if [ ! -d ".secrets" ]; then
    mkdir -p ".secrets"
    portpass=$(openssl rand -base64 12)
    echo "$portpass" >> .secrets/portainer-admin-password
  fi
}

createuser() {
  printf "\ncreateuser(): Started...\n"
  if [ ! -z "$1" ]; then
    printf "Installing (${YEL}apache2-utils${NC}). \n"
    sudo apt install apache2-utils
    if [ ! -d ".auth" ]; then
      mkdir -p ".auth"
    fi
    pass=$(openssl rand -base64 12)
    htpasswd -nb $1 $pass >> $users
    printf "createuser(): ${GRN}A user ${YEL}$1${GRN} has been assigned an automatically generated password: ${YEL}$pass${NC}${GRN}. Remember it!${NC} \n"
    printf "createuser(): ${GRN}A respective auth pair has been generated in ${BLU}$users${NC} \n"
  else
    printf "createuser(): ${RED}Please provide a username as a parameter!${NC}\n"
  fi
}

init() {
  if [[ ! -x "$(command -v docker)" ]]; then
    printf "\ninit(): You must install ${RED}docker${NC} on your machine. Aborted. \n"
    exit 1
  fi

  if [[ ! -x "$(command -v docker-compose)" ]]; then
    printf "\ninit(): You must install ${RED}docker-compose${NC} on your machine. Aborted. \n"
    exit 1
  fi

  #checking BasicAuth:
  if [ ! -r ${users} ]
  then
    createuser $adminuser
  fi

  createnet
  createsecrets

  # copying _env into the .env if not found:
  if [ ! -r ${env} ]
  then
    printf "\ninit(): Environment file is not found.\n"
    read -p "Input your domain name (e.g. mydomain.com): " domain
    if [ ! -z $domain ]
    then
        printf "init(): Creating (${YEL}${env}${NC}). \n"
        cp '_env' ${env}
        sed -i "s|#PORTAINER_AGENT_SECRET#|$(openssl rand -base64 16)|g" ${env}
        sed -i "s|#DOMAIN#|$domain|g" ${env}
        printf "\ninit(): Check the ${YEL}${env}${NC} and make sure all parameters are correct and subdomains are registered in your DNS settings. \n"
    else
        printf "init(): ${RED}Empty domain. Installation aborted.${NC} \n"
        exit 1
    fi
  fi

  #checking if .env created successfully:
  if [ -r ${env} ]
  then
    source ${env}
    printf "COMPOSE: ${YEL}${COMPOSE_FILE}${NC}. \n"
  else
    printf "Error creating environment file ${RED}${env}${NC}. Please, check if an ${BLU}_env${NC} file available, resolve and restart...\n"
    exit 1
  fi
}


main() {
    printf "\n Variables: \n"
    printf "                       env: ${BLU}${env}${NC}\n"
    printf "     DASHBOARD_TRAEFIK_URL: ${BLU}${DASHBOARD_TRAEFIK_URL}${NC} \n"
    printf "     PORTAINER_TRAEFIK_URL: ${BLU}${PORTAINER_TRAEFIK_URL}${NC} \n"
    printf "         VAULT_TRAEFIK_URL: ${BLU}${VAULT_TRAEFIK_URL}${NC} \n"

    case "${1}" in
        --pull | -p )
            printf "Docker prune images with filter ${GRN}${PRUNE_FILTER}${NC} \n"
            docker image prune -a --force --filter "${PRUNE_FILTER}"
            docker-compose pull
            ;;
        --up | -u )
            docker-compose up -d "${@:2}"
            ;;
        --down | -d )
            docker-compose down
            ;;
        --restart | -r )
            docker-compose down
            docker-compose up -d "${@:2}"
            ;;
        --setpass | -s )
            createuser $2
            ;;
        * ) 
            printf "\n \
                    Usage:$BLU ${0} $GRN[parameters]$NC\n \
                    $GRN--pull, -p$NC\t\t Pull the repo from registry\n \
                    $GRN--up,-u$NC\t\t Up the repo\n \
                    $GRN--down,-d$NC\t\t Down the repo\n \
                    $GRN--restart,-r$NC\t Cold-restart the repo\n \
                    $GRN--setpass,-s$NC\t Set password for$GRN username$NC (provided as a second parameter)\n \
                    "
            ;;
    esac

}

printf "${NC}Started: ${YEL}" && date && printf "${NC}\n"
init
time main "$@"
printf "${NC}Finished: ${YEL}" && date && printf "${NC}\n"