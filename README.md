# A collection of containerized apps:
* heimdall (web app dashboard)
* mailpit (SMTP/WEB interceptor)
* maintenance (page "maintenance works")
* mongodb (Mongo Database + Mongo Express)
* squidex (Squidex headless CMS, requires MongoDB)
* traefik (cloud proxy server)
* uptime-kuma (service uptime monitor)
* whoami (info container by Traefik)
* zentrale (hashiCorp Vault + Portainer + Traefik)

Prerequisites:
- [Docker Engine](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- [Docker Compose](https://docs.docker.com/compose/install/)
```
sudo apt update && sudo apt install -y net-tools bridge-utils mc tmux htop
```
