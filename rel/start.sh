#!/bin/bash
# With help from https://dogsnog.blog/2018/02/02/a-docker-based-development-environment-for-elixirphoenix/

./bin/production eval "JackJoe.ReleaseTasks.migrate_and_seed"

./bin/production start
