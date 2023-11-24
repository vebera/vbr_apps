# Traefik + SSL certificates

This repository will help you set up Traefik v2.5.5 over HTTPS in Ubuntu.

prerequisites:
- either you intend to use LetsEncrypt certificates
- or you have dedicated SSL certificates stored somewhere in a folder

subdomains:
- agent: for portainer agent
- dash: for traefik dashboard

## Setup

1. Copy `_env` to `.env`. Then fill the `.env` file with your credentials and your domain names.
2. For dedicated SSL certs:
- make sure you specify `docker-compose-ssl.yml` in the `COMPOSE_FILE` variable.
- Edit `dynamic.yml` and specify certificate filenames
3. set up a basic auth password to protect traefik dashboard
```shell
./stack.sh -p `username` `password`
```
4. Create proxy network in docker:
```
docker network create proxy
```
5. Spin up the container, it should up the dashboard portal (`dash.yourdomain.tld`) with Basic Auth protection (the username and password you created in p.3):
```
./stack.sh -u
```

**NOTE:** Traefik will automatically renew the LetsEncrypt certificate every 3 months.

Enjoy!
