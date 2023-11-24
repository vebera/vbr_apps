#!/bin/bash

# Error handling
set -o errexit          # Exit on most errors
set -o errtrace         # Make sure any error trap is inherited
set -o pipefail         # Use last non-zero exit code in a pipeline
#set -o nounset          # Exits if any of the variables is not set


GRN='\033[0;32m' && YEL='\033[1;33m' && RED='\033[0;31m' && BLU='\033[0;34m' && NC='\033[0m'
declare env=".env"

##reading .env parameters from the script folder
if [ ! -r $env ]; then
  printf "  Missing config file ${RED}$env${NC} in the folder ${RED}$PWD${NC}. Fix it and try again.\n"
  exit 1
else
  source $env
  printf "COMPOSE: ${YEL}${COMPOSE_FILE}${NC}. \n"
fi

main() {
    case "${1}" in
        --pull | -p )
            docker-compose -f ${COMPOSE_FILE} pull
            ;;
        --up | -u )
            docker-compose -f ${COMPOSE_FILE} pull
            docker-compose -f ${COMPOSE_FILE} up -d "${@:2}"
            ;;
        --down | -d )
            docker-compose -f ${COMPOSE_FILE} down
            ;;
        --restart | -r )
            docker-compose -f ${COMPOSE_FILE} pull
            docker-compose -f ${COMPOSE_FILE} down
            docker-compose -f ${COMPOSE_FILE} up -d "${@:2}"
            ;;
        * ) 
            printf "usage: ${0} [arg]\n \
                    $GRN--up,-u$NC\t\t Up the repo\n \
                    $GRN--down,-d$NC\t\t Down the repo\n \
                    $GRN--restart,-r$NC\t Cold-restart the repo\n \
                    "
            ;;
    esac

}

printf "${NC}Started: ${YEL}" && date && printf "${NC}\n"
time main "$@"
printf "${NC}Finished: ${YEL}" && date && printf "${NC}\n"