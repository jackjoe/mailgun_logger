#!/bin/bash

./bin/production eval "JackJoe.ReleaseTasks.migrate_and_seed"

./bin/production start
