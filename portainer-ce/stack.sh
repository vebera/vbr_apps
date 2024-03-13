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

createnet() {
  if [ ! "$(docker network ls | grep proxy)" ]; then
    printf "\ncreatenet(): Creating docker network (${YEL}proxy${NC}). \n"
    sudo docker network create proxy
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

  createnet

  # copying _env into the .env if not found:
  if [ ! -r ${env} ]
  then
    printf "\ninit(): Environment file is not found.\n"
    printf "init(): Creating (${YEL}${env}${NC}). \n"
    cp '_env' ${env}
    printf "\ninit(): Check the ${YEL}${env}${NC} and make sure all parameters are correct and subdomains are registered in your DNS settings. \n"
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
    printf "      env: ${BLU}${env}${NC}\n"

    case "${1}" in
        --pull | -p )
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
        * ) 
            printf "\n \
                    Usage:$BLU ${0} $GRN[parameters]$NC\n \
                    $GRN--pull, -p$NC\t\t Pull the repo from registry\n \
                    $GRN--up,-u$NC\t\t Up the repo\n \
                    $GRN--down,-d$NC\t\t Down the repo\n \
                    $GRN--restart,-r$NC\t Cold-restart the repo\n \
                    "
            ;;
    esac

}

printf "${NC}Started: ${YEL}" && date && printf "${NC}\n"
init
time main "$@"
printf "${NC}Finished: ${YEL}" && date && printf "${NC}\n"