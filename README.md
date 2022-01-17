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
- `docker-compose up -d node` to run the node, `docker-compose up -d testnet`
  to run a testnet node

Make sure you expose port 6432 to the world if you want incoming connections.
This means using the `ports` directive in your override, and may require
firewall changes as well.

Need to run subcommands / flags of the node command? You can't (easily) just
run the node command because the docker image is set up in a more secure (read:
harder to deal with) way. So there's an entrypoint that tries to be helpful -
instead of running a command inside the running container, you do a
`docker-compose run` with whatever flags you need:

```bash
docker-compose run --rm node -help
docker-compose run --rm node -reindex
docker-compose run --rm node -printtoconsole=0
```

And so forth. The container prefixes your flagged command with "dynamo-core",
and adds various flags to make sure the data dir, config file, etc. are all set
properly.

## For Testing Miners

It's a pain to solo-test miners, so I've got a docker-compose setup for running
four fake testnet nodes locally. There's a command, `fake`, that runs
docker-compose with the proper flags to run that setup much the same as you'd
run `docker-compose` for normal use. e.g., instead of `docker-compose up`,
you'd use `./fake up`. For the "cli -getinfo" command, simply enter:

    ./fake exec node cli -getinfo

This makes it easy to test a miner against a functional node without having to
ask moderators to spin up / reset the testnet. A typical dev/test loop might
look something like this:

- Start up all four fake nodes: `./fake up -d`
- Verify nodes: `./fake exec node cli -getinfo`
- Test a miner - make sure it's getting blocks
- Maybe watch the "main" fake node's logs: `./fake logs node -f`
- Reset the chain data (destroy all blocks) when blocks are taking too long or
  you've got a benchmark to run or something: `./fake down -v`.

A few caveats exist. A "fresh" blockchain will not behave like the real thing.
Difficulty will be absurdly low, blocks will be generated far faster than on
the real chain, etc.

If you don't understand how `./fake` runs docker, *go learn more*. You can
easily mess yourself up playing with this stuff if you don't at least
understand what the one-liner in `./fake` actually does.

If you don't know much about blockchains, this setup will be fine, but you
probably aren't going to get much out of it because what you see may not make
much sense. Coming from the real network to a toally internal testnode can be a
huge shift. It's a great way to test, but it **will** have some significant
differences.

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

This node *can* run on a low-end VPS, though you will likely need to be a
decent sysadmin to do so. You'll have to make sure you manage things like
docker logs, disk usage, etc.

A "low-end" VPS looks a bit like this:

- 1 vCPU
- 2GB RAM
- 50GB Disk
- 2TB bandwidth per month

### CPU

The CPU seems to be pretty idle after initial sync. No real problems here, and
you can even run CPU-heavy operations without anything negative as far as I can
tell.

### RAM

RAM usage may be a problem if you run other processes. v1.0 of the node was
able to run for several days on a 1GB linode with other processes running
alongside it. Unfortunately, node v1.1 can't. It seems to need a full gig of
RAM all to itself.

While syncing, RAM seems to just continually rise. After the full sync, my node
was using over a gig of RAM. I stopped and restarted it, and it's settled back
to about 670MB. I suspect there's some small memory leak that is only a problem
when processing a huge number of blocks.

There's an example in the `docker-compose.override-example.yml` file that can
help reduce RAM. By using the `printtoconsole=0` flag, journald and
docker-compose use a good deal less RAM. This comes at the cost of losing *all*
logging, however, so it's probably a good idea to use this flag only if you're
certain you absolutely need it.

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
