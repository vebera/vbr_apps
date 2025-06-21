## How to install

### Create a network

```bash
    docker network create --driver=bridge --subnet=172.22.0.0/16 --gateway=172.22.0.1 dns_local
```

### Spin the container

```bash
docker compose up -d
```

When getting an error: 'Error starting userland proxy: listen tcp 0.0.0.0:53: bind: address already in use', run the following commands:
```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```
and spin the docker compose again.

### point local DNS resolver to 172.22.0.1

## Test
All applications have their subdomains defined in the `local.lab.zone` file, like `portainer.local.lab`
You can test it by:
```bash
nslookup portainer.local.lab 172.22.0.1
```