#!/bin/bash

# Error handling
set -o errexit          # Exit on most errors
set -o errtrace         # Make sure any error trap is inherited
set -o pipefail         # Use last non-zero exit code in a pipeline
#set -o nounset          # Exits if any of the variables is not set

GRN='\033[0;32m' && YEL='\033[1;33m' && RED='\033[0;31m' && BLU='\033[0;34m' && NC='\033[0m'

#folder where the current script is located
declare HOME="$(cd "$(dirname "$0")"; pwd -P)"
declare env='.env'

init() {

  #checking if .env created successfully:
  if [ -r ${env} ]
  then
    source ${env}
  else
    printf "Error creating environment file ${RED}${env}${NC}. Please, check if an ${BLU}_env${NC} file available, resolve and restart...\n"
    exit 1
  fi
}


main() {
    printf "\n   Variables: \n"
    printf "     instance : ${YEL}$COMPOSE_PROJECT_NAME${NC}. You can provide a new instance name as a parameter.\n"
    printf "          env : ${BLU}${env}${NC}\n"

    case "${1}" in
        --pull | -p )
            docker image prune -a --force --filter "until=72h"
            docker-compose -f ${COMPOSE_FILE} pull "${@:3}"
            ;;
        --up | -u )
            printf "${GRN}docker-compose -f ${COMPOSE_FILE} up -d "${@:3}"${NC} \n"
            docker-compose -f ${COMPOSE_FILE} up -d "${@:3}"
            ;;
        --down | -d )
            docker-compose -f ${COMPOSE_FILE} down
            ;;
        --restart | -r )
            docker-compose -f ${COMPOSE_FILE} down
            docker-compose -f ${COMPOSE_FILE} up -d "${@:3}"
            ;;
        * ) 
            printf "\n \
                    Usage:${BLU} ${0} ${GRN}parameters${NC}\n \
                    ${GRN}--pull, -p${NC}\t\t Pull the repo from registry\n \
                    ${GRN}--up,-u${NC}\t\t Up the repo\n \
                    ${GRN}--down,-d${NC}\t\t Down the repo\n \
                    ${GRN}--restart,-r${NC}\t Cold-restart the repo\n \
                    \n \
                    Example:${BLU} ${0} ${GRN}-u${NC}\n \
                    "
            ;;
    esac

}

init "$@"
time main "$@"
