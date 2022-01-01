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

Do **not** expose port 6433 to anything you don't implicitly trust. Even with a
strong RPC user / password combo this can be risky if you don't know what
you're doing. For instance, it's fine to exposing 6433 using firewall rules to
only allow your IP address in, the use this node to mine. But if you mess up
those firewall rules and somebody spams your node... well, ye be warned.

# Using the Command-Line Interface

The container has a handy script for CLI access. Once you have a container up
and running, simply run your commands within the running container, e.g.:

```
docker-compose exec node cli -getinfo
docker-compose exec node cli getpeerinfo
```

## Install as a systemd service

This assumes your repo lives in `opt/dmo-node`. If it doesn't, you'll need to
either move it there or alter the service file. The former is probably easiest
to keep consistent with this repo.

Install the service unit: `systemctl enable $(pwd)/dmo-node.service`. Then
simply start it: `systemctl start dmo-node`. Easy!
