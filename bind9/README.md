## How to install

### Create networks

```bash
docker network create --driver=bridge --subnet=172.22.0.0/16 --gateway=172.22.0.1 dns_local
```

and

```bash
docker network create --driver bridge isolated
```

### Spin the container

```bash
docker compose up -d
```

### point local DNS resolver to 172.22.0.1

## Test
All applications have their subdomains defined in the `local.lab.zone` file, like `portainer.local.lab`
You can test it by:
```bash
nslookup portainer.local.lab 172.22.0.1
```