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


## Traefik & Letsencrypt
Must be spinned first!


## Portainer Agent
Spin if you have a master Portainer app installed elsewhere

## Change location for docker:
```bash
sudo nano /etc/docker/daemon.json
```
Paste the text:
```
{
  "data-root": "/mnt/disk/docker"
}
```
save and reboot:
```bash
sudo reboot
```
## Troubleshooting
### If containers do not get internet access
1. Follow [this solution](https://forums.docker.com/t/solved-no-network-when-running-a-container-in-arch-linux/5494/6)
NOTE: connman can interfere and modify ip route tables!
```
sudo apt update && sudo apt install -y connman
sudo nano /etc/connman/main.conf
```
2. add this line
```
[General]
NetworkInterfaceBlacklist=vmnet,vboxnet,virbr,ifb,docker,veth,eth,wlan
```

3. Save and reboot
```
sudo reboot
```
