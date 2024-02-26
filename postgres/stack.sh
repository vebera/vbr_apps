#!/bin/bash

# Error handling
set -o errexit          # Exit on most errors
set -o errtrace         # Make sure any error trap is inherited
set -o pipefail         # Use last non-zero exit code in a pipeline
#set -o nounset          # Exits if any of the variables is not set

GRN='\033[0;32m' && YEL='\033[1;33m' && RED='\033[0;31m' && BLU='\033[0;34m' && NC='\033[0m'

declare env=".env"

init() {
  if [ -r ${env} ]
  then
    source ${env}
  else
    printf "Error creating environment file ${RED}${env}${NC}. Please, check if an ${BLU}_env${NC} file available, resolve and restart...\n"
    exit 1
  fi
}

main() {
    printf "\n   Variables : \n"
    printf "      instance : ${YEL}$COMPOSE_PROJECT_NAME${NC}\n"
    printf "  compose file : ${BLU}$COMPOSE_FILE${NC}\n"
    printf "           env : ${BLU}${env}${NC}\n"

    case "${1}" in
        --pull | -p )
            docker image prune -a --force --filter "until=72h"
            docker-compose --env-file ${env} -f ${COMPOSE_FILE} pull "${@:3}"
            ;;
        --up | -u )
            docker-compose --env-file ${env} -f ${COMPOSE_FILE} up -d "${@:3}"
            ;;
        --down | -d )
            docker-compose --env-file ${env} -f ${COMPOSE_FILE} down
            ;;
        --build | -b )
            docker-compose --env-file ${env} -f ${COMPOSE_FILE} up -d --build "${@:3}"
            ;;
        --restart | -r )
            docker-compose --env-file ${env} -f ${COMPOSE_FILE} down
            docker-compose --env-file ${env} -f ${COMPOSE_FILE} up -d "${@:3}"
            ;;
        * )
            printf "\n \
                    Usage:${BLU} ${0} ${GRN}parameters${NC}\n \
                    ${GRN}--pull, -p${NC}\t\t Pull the repo from registry\n \
                    ${GRN}--up,-u${NC}\t\t Up the repo\n \
                    ${GRN}--build,-b${NC}\t\t Build the repo\n \
                    ${GRN}--down,-d${NC}\t\t Down the repo\n \
                    ${GRN}--restart,-r${NC}\t Cold-restart\n \
                    \n \
                    Example:${BLU} ${0} ${GRN}-u${NC}\n \
                    \n \
                    ${GRN}pgAdmin:${NC}\t http://localhost:${PGADMIN_OUTER_PORT:-5050}/login \n \
                    \n \
                    "
            ;;
    esac

}

init "$@"
time main "$@"