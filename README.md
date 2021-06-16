## rdt12/paws

This repository contains a Dockerfile for building a container based on [the official Scientific Linux 7 docker image](https://hub.docker.com/_/sl).

It contains:

- [Paws-0.43] - John Scoles' Perl library for interacting with AWS (and dependencies)
- System `jq` package
- system `awscli` package

This repository also contains some example scripts using Paws in the `examples` directory.

The liberal use of `Data::Dumper` and comparison to the JSON output of the aws cli
can aid in  understanding the structures returned from Paws functions.


