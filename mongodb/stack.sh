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
declare users=".auth/users.txt"
declare adminuser="boss"
declare env=".env"

createnet() {
  if [ ! "$(docker network ls | grep proxy)" ]; then
    printf "\ncreatenet(): Creating docker network (${YEL}proxy${NC}). \n"
    sudo docker network create proxy
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

  # copying _env into the .env if not found:
  if [ ! -r ${env} ]
  then
    printf "\ninit(): Environment file is not found.\n"
    read -p "Input your MongoExpress domain name (e.g. dbadmin.freelan.one): " domain
    if [ ! -z $domain ]
    then
        printf "init(): Creating (${YEL}${env}${NC}). \n"
        cp '_env' ${env}
        sed -i "s|#EXPRESS_URL#|$domain|g" ${env}
        admin=$(openssl rand -base64 6)
        pass=$(openssl rand -base64 12)
        sed -i "s|#EXPRESS_USER#|$admin|g" ${env}
        sed -i "s|#EXPRESS_PASS#|$pass|g" ${env}
        printf "init(): ${GRN}A user ${YEL}$admin${GRN} and a password: ${YEL}$pass${NC}${GRN} generated for the app ${YEL}https://$domain${NC}${GRN}. Remember it!${NC} \n"
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
    case "${1}" in
        --password | -p )
            createuser $2
            ;;
        --backup | -b )
            if [ -d "${EXT_BACKUP}" ]; then
              if [ ! -z "$2" ]; then
                docker exec -it ${CONTAINER_NAME} bash -c "mongodump --db ${2} --gzip --out=${INT_BACKUP}/${today}"
                printf "dump files for database ${GRN}${2}${NC} are stored in ${GRN}${HOME}/${EXT_BACKUP}/${today}${NC} !\n"
              else
                printf "${RED}Missing database name!${NC}\n"
              fi
            else
              printf "${RED}Backup folder ${BLU}${EXT_BACKUP}${RED} does not exist!${NC}\n"
            fi
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
        --restore )
            if [ -d "${EXT_BACKUP}" ]; then
              if [ ! -z "$2" ] && [ ! -z "$3" ] && [ -d "${EXT_BACKUP}"/"$3" ]; then
                printf "${RED} RESTORE STARTED ${NC}\n"
                docker exec -it ${CONTAINER_NAME} bash -c "mongorestore --db ${2} --gzip --drop ${INT_BACKUP}/${3}"
                printf "${RED} RESTORE FINISHED ${NC}\n"
               else
                printf "${RED}Missing database name, folder name or the folder does not exist!${NC}\n"
              fi
            else
              printf "${RED}Backup folder ${BLU}${EXT_BACKUP}${RED} does not exist!${NC}\n"
            fi
            ;;
        * ) 
            printf "usage: ${0} [arg]\n \
                    $GRN--backup,-b$NC\t Back-up the database. 2nd argument is a database name.\n \
                    $GRN--password,-p$NC\t Generate a basic authentication pair.\n \
                    $GRN--up,-u$NC\t\t Up the repo. Provide$GRN express$NC as a second parameter to launch mongo-express\n \
                    $GRN--down,-d$NC\t\t Down the repo.\n \
                    $GRN--restart,-r$NC\t Cold-restart the repo.\n \
                    $GRN--restore$NC\t\t Restore the database. 2nd argument is a database name and 3rd is a folder with backup (inside $GRN${EXT_BACKUP}$NC)!\n"
            ;;
    esac

}

printf "${NC}Started: ${YEL}" && date && printf "${NC}\n"
init
time main "$@"
printf "${NC}Finished: ${YEL}" && date && printf "${NC}\n"