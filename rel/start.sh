#!/bin/bash
# With help from https://dogsnog.blog/2018/02/02/a-docker-based-development-environment-for-elixirphoenix/

set -e

# Wait for Postgres to become available.
until psql -h db -U "postgres" -c '\q' 2>/dev/null; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

./bin/production eval "JackJoe.ReleaseTasks.migrate_and_seed"

./bin/production start
