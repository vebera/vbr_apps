#!/bin/bash

# Error handling
set -o errexit          # Exit on most errors
set -o errtrace         # Make sure any error trap is inherited
set -o pipefail         # Use last non-zero exit code in a pipeline
#set -o nounset          # Exits if any of the variables is not set

# colors
GRN='\033[0;32m' && YEL='\033[1;33m' && RED='\033[0;31m' && BLU='\033[0;34m' && NC='\033[0m'
#folder where the current script is located
declare HOME="$(cd "$(dirname "$0")"; pwd -P)"
declare today=$(date +"%Y%m%d")
declare env=".env"

init() {
  if [[ ! -x "$(command -v docker)" ]]; then
    printf "\ninit(): You must install ${RED}docker${NC} on your machine. Aborted. \n"
    exit 1
  fi

  if [[ ! -x "$(command -v docker-compose)" ]]; then
    printf "\ninit(): You must install ${RED}docker-compose${NC} on your machine. Aborted. \n"
    exit 1
  fi

  # copying _env into the .env if not found:
  if [ ! -r ${env} ]
  then
    printf "\ninit(): Environment file is not found.\n"

    read -p "Input app domain name (e.g. squidex.demo.com, default: localhost): " domain
    if [[ -z $domain ]]; then
      domain="localhost"
    fi

    read -p "Input app port (e.g. 8080, default: 80): " port
    if [[ -z $port ]]; then
      port=""
    fi

    read -p "Input your email id, which will be used as login (default admin@demo.com): " email
    if [[ -z $email ]]; then
      email="admin@demo.com"
    fi

    read -rp "Is this site using SSL? [y/N] " confirmssl
    if ! [[ "$confirmssl" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      squidex_protocol="http"
      squidex_force_https=false
    else
      squidex_protocol="https"
      squidex_force_https=true
    fi


    if [ ! -z $email ]
    then
        printf "init(): Creating (${YEL}${env}${NC}). \n"
        cp '_env' ${env}
        sed -i "s|#SQUIDEX_PROTOCOL#|$squidex_protocol|g" ${env}
        sed -i "s|#SQUIDEX_FORCE_HTTPS#|$squidex_force_https|g" ${env}
        sed -i "s|#SQUIDEX_URL#|$domain|g" ${env}
        sed -i "s|#SQUIDEX_PORT#|$port|g" ${env}
        sed -i "s|#EMAIL#|$email|g" ${env}
        pass=$(openssl rand -base64 16)
        sed -i "s|#PASSWORD#|$pass|g" ${env}
        printf "createuser(): ${GRN}A user ${YEL}$email${GRN} has been assigned an automatically generated password: ${YEL}$pass${NC}${GRN}. Remember it!${NC} \n"
        printf "\ninit(): Check the ${YEL}${env}${NC} and make sure all parameters are correct. \n"
    else
        printf "init(): ${RED}Empty email. Installation aborted.${NC} \n"
        exit 1
    fi
  fi

  ##reading .env parameters from the script folder
  if [ ! -r $env ]; then
    printf "Missing config file ${RED}$env${NC} in the folder ${RED}$HOME${NC}. Fix it and try again.\n"
    exit 1
  else
    source $env
    printf "COMPOSE: ${YEL}${COMPOSE_FILE}${NC}. \n"
  fi

}


main() {
    case "${1}" in
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
            printf "usage: ${0} [arg]\n \
                    $GRN--up,-u$NC\t\t Up the repo.\n \
                    $GRN--down,-d$NC\t\t Down the repo.\n \
                    $GRN--restart,-r$NC\t Cold-restart the repo.\n \
                    "
            ;;
    esac

}



printf "${NC}Started: ${YEL}" && date && printf "${NC}\n"
init
time main "$@"
printf "${NC}Finished: ${YEL}" && date && printf "${NC}\n"