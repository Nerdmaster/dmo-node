# DMO-Node

This project aims to be a very simple one-step setup for running just the DMO
node and nothing else. The docker image will be pushed to docker hub for others
to easily use on minimal hardware.

There's a docker-compose file to simplify building it, and an example
`docker-compose.override.yml` to show how to expose ports and set the
environment. As those can vary depending on where one runs the node, they
aren't kept in the original docker-compose file.

Usage: typical docker commands. `docker-compose pull`, `docker-compose up`,
etc. To build the node (instead of pulling it from dockerhub), a simple
`docker-compose build` should suffice, but be warned it can be very
resource-intensive (a small VPS may not work).
