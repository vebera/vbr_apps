#!/bin/bash

# Error handling
set -o errexit          # Exit on most errors
set -o errtrace         # Make sure any error trap is inherited
set -o pipefail         # Use last non-zero exit code in a pipeline
#set -o nounset          # Exits if any of the variables is not set


#folder where the current script is located
declare HOME="$(cd "$(dirname "$0")"; pwd -P)"
declare today=$(date +"%Y%m%d")
GRN='\033[0;32m' && YEL='\033[1;33m' && RED='\033[0;31m' && BLU='\033[0;34m' && NC='\033[0m'
declare env=".env"

init() {
##reading .env parameters from the script folder
if [ ! -r $env ]; then
  cp _env $env
  printf "Missing config file ${RED}$env${NC} in the folder ${RED}$HOME${NC}. A new file is created, edit it and try again.\n"
  exit 1
else
  source $env
  printf "COMPOSE: ${YEL}${COMPOSE_FILE}${NC}. \n"
fi
}

main() {
    case "${1}" in
        --password | -p )
            if [ ! -z "$2" ] && [ ! -z "$3" ]; then
              if [ ! -d ".users" ]; then
                mkdir -p ".users"
              fi
              htpasswd -nb $2 $3 >> ".users/users.txt"
              printf "${GRN}an auth pair has been generated in ${BLU}.users/users.txt${NC}\n"
            else
              printf "${RED}Either a user or a password missing!${NC}\n"
            fi
            ;;
        --up | -u )
            docker-compose -f ${COMPOSE_FILE} up -d
            ;;
        --down | -d )
            docker-compose -f ${COMPOSE_FILE} down
            ;;
        --restart | -r )
            docker-compose -f ${COMPOSE_FILE} down
            docker-compose -f ${COMPOSE_FILE} up -d
            ;;
        * ) 
            printf "usage: ${0} $GRN[arg]$NC $YEL[parameters]$NC\n \
                    $GRN--password,-p$NC\t Generate a basic authentication pair with provided ${YEL}username${NC} and a ${YEL}password${NC}\n \
                    $GRN--up,-u$NC\t\t Up the repo.\n \
                    $GRN--down,-d$NC\t\t Down the repo.\n \
                    $GRN--restart, -r$NC\t Cold-restart the stack\n
                    \n\
                    Example:${BLU} ${0} ${GRN}-p${NC} ${YEL}admin mysecretpassword${NC}\n \
                    "
            ;;
    esac

}

printf "${NC}Started: ${YEL}" && date && printf "${NC}\n"
init "$@"
time main "$@"
printf "${NC}Finished: ${YEL}" && date && printf "${NC}\n"