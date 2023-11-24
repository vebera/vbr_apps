# HashiCorp Vault + Portainer + Traefik + LetsEncrypt

This repository will help you set up Portainer served by Traefik v2.6.9 over HTTPS (Let's Encrypt) in Ubuntu

Prerequisites:
- [Docker Engine](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- [Docker Compose](https://docs.docker.com/compose/install/)

subdomains:
- portainer: for portainer
- dash: for traefik dashboard
- vault: for vault (by default is not initialized)

## Setup

1. Simply `git clone` the repository into your server's directory:
```shell
git clone git@ssh.dev.azure.com:v3/wizzpaytech/Deployments/zentrale
cd zentrale
```
2. Launch stack maintenance script and specify the target domain name
```shell
sudo ./stack.sh
```
3. Spin a stack:
```shell
sudo ./stack.sh -u
```

**NOTE:** Traefik will automatically renew the certificate every 3 months.

## Vault initiation:
1. Comment lines `- ./vault-init/config.hcl:/vault/config/config.hcl` and `command: server` for the `vault-server` service and perform the first start of the docker-compose file:
```shell
sudo docker-compose up -d vault
```
Look up in the logs of the `vault-server` container 
```shell
sudo docker ps
sudo docker logs <vault_container_id>
```
and copy unseal and token keys from the server console.
2. Specify variable `VAULT_DEV_ROOT_TOKEN_ID` in the `.env`
3. Stop it and start again with the `vault-init` profile:
```shell
docker-compose down
docker-compose up -d vault vault-init
```
4. Stop it and, uncomment respective lines (see p.1) in the docker-compose.yml and restart the vault in the server mode:
```shell
docker-compose down
docker-compose up -d vault
```

Thats it!


## Exposing Docker sockets via portainer-agent (Optional)

ask vasyl@wizzfinancial.com
Note: use the same PORTAINER_AGENT_SECRET !
