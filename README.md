# DMO-Node

This is a blatant ripoff of the
[Official Docker Node](https://github.com/dynamofoundation/docker-node) DMO
project. This was created to provide a much smaller option for node-only
deployments. And it's basically built for me, so it may or may not work for
others, though I will try to make improvements.

This project aims to be a very simple one-step setup for running just the DMO
node and nothing else. The docker image will be pushed to docker hub for others
to easily use on minimal hardware.

There's a docker-compose file to simplify building it, and an example
`docker-compose.override.yml` to show how to expose ports and set the
environment. As those can vary depending on where one runs the node, they
aren't kept in the original docker-compose file.

## Usage

Typical docker stuff:

- Consider copying `docker-compose.override-example.yml` to a local
  `docker-compose.override.yml` file so you can customize it for your
  environment (particularly the RPC user / pass)
- `docker-compose pull` will pull the latest node image from dockerhub
- `docker-compose build` will build a local node for you, but this will take
  several minutes, and is very resource-intensive (a small VPS cannot compile
  the app since it needs a ton of RAM)

Make sure you expose port 6432 to the world if you want incoming connections.
This means using the `ports` directive in your override, and may require
firewall changes as well.

## Security

Do **not** expose port 6433 to anything you don't implicitly trust. Even with a
strong RPC user / password combo this can be risky if you don't know what
you're doing. For instance, it's fine to expose 6433, then use firewall rules
to only allow your IP address in -- this could allow you to use this node for
mining from external systems. But if you mess up those firewall rules and
somebody spams your node... well, ye be warned.

Note that if you're using docker on a system that's not behind other firewalls,
it *will* need to control your iptables, and it **will** expose all services to
the world. You have to set this up very carefully or else all your docker
services are at risk. Your best bet is just not exposing the docker server to
the Internet directly. Use a separate firewall, keep the server on a local
network and proxy to it (HAProxy, for instance), etc.

## Using the Command-Line Interface

The container has a handy script for CLI access. Once you have a container up
and running, simply run your commands within the running container, e.g.:

```
docker-compose exec node cli -getinfo
docker-compose exec node cli getpeerinfo
```

Personally I like to make an alias when I'm gonna do a lot of this sort of
thing: `alias cli='docker-compose exec node cli'`.

## Install as a systemd service

This assumes your repo lives in `/opt/dmo-node`. If it doesn't, you'll need to
either move it there or alter the service file. The former is probably easiest
to keep consistent with this repo.

Install the service unit: `systemctl enable $(pwd)/dmo-node.service`. Then
simply start it: `systemctl start dmo-node`. Easy!

You can interact with the docker container as normal, though to start and stop
it you should stick to `systemctl` commands.

## Hardware Needs

This node *can* run on a very low-end VPS, though you will likely need to be a
decent sysadmin to do so. You'll have to make sure you manage things like
docker logs, disk usage, etc.

A "low-end" VPS looks a bit like this:

- 1 vCPU
- 1GB RAM
- 25GB Disk
- 1TB bandwidth per month

The CPU seems to be pretty idle after initial sync. RAM usage, so long as you
don't try to *build* your image on the VPS, stays below 600MB, and the server
seems okay to share it with other applications.

Disk and bandwidth, however, may be problems.

### Disk

Disk is the biggest problem, and one you'll have to manage carefully on a truly
low-end VPS. Docker will fill up your logs if you aren't careful. You almost
certainly will have to modify your `/etc/docker/daemon.json` file to add, at a
minimum, some logging configuration, e.g.:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Besides docker, other logs may be an issue and you'll have to figure that out
on your own, as it can vary from distro to distro as well as other apps you may
be running. Additionally, the blockchain will only grow. As of around block one
million, roughly six months in, the block data uses about a gig of storage.

You will probably need to watch your disk usage closely, and consider adding
more or upgrading your VPS.

### Bandwidth

The bandwidth issue isn't a major problem, but you can expect a running node to
use around 5GB a day. That means in any given month, the node is currently
going to use 15% of your available bandwidth. This could be a problem if you
have other services and/or DMO nodes show spikes in network use anytime soon.
