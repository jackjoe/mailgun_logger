# Mailgun Logger

[![Build Status](https://travis-ci.com/jackjoe/mailgun_logger.svg?branch=master)](https://travis-ci.com/jackjoe/mailgun_logger)

Simple admin tool to get Mailgun persistence ad infinite.

MailgunLogger is a simple admin tool that uses the Mailgun API to retrieves events on a regular basis from Mailgun - who only provide a limited time of event storage - and stores them inside a Postgres database.
For efficiency and less complexity, it retrieves events for the last two days (free accounts offer up to three days of persistence) and then inserts everything. Only new events will pass the unique constraint on the db.

This is done because, as stated in the Mailgun docs, it is not guaranteed that for a given time period, all actual events will be ready, since some take time to get into the system although they already happened.

See the docs for implementation details.

_**IMPORTANT**_

_This application is not affiliated, associated, authorized, endorsed by, or in any way officially connected with Mailgun, or any of its subsidiaries or its affiliates. The official Mailgun website can be found at [Mailgun](https://mailgun.com)._

_This is NOT meant as a replacement for the excellent online tooling provided by Mailgun. Just simple storage, that's it._

_Jack + Joe is not responsible for your use of this tool, neither for any persistence guarantees. Free comes at a price :)_

## Installation

MailgunLogger is available as a Docker image at [Docker](https://hub.docker.com/r/jackjoe/mailgun_logger). To run it:

### Docker

```bash
$ docker run -d -p 5050:5050 \
  -e "ML_DB_USER=username" \
  -e "ML_DB_PASSWORD=password" \
  -e "ML_DB_NAME=mailgun_logger" \
  -e "ML_DB_HOST=my_db_host" \
  --name mailgun_logger jackjoe/mailgun_logger
```

### Docker Compose

With the following `docker-compose.yml`:

```yml
version: "3"

services:
  db:
    image: postgres
    networks:
      - webnet
    environment:
      POSTGRES_PASSWORD: logger
      POSTGRES_USER: logger
      POSTGRES_DB: mailgun_logger

  web:
    image: jackjoe/mailgun_logger
    ports:
      - "5050:5050"
    networks:
      - webnet
    environment:
      DB_HOST: db
      ML_DB_USER: logger
      ML_DB_PASSWORD: logger
      ML_DB_NAME: mailgun_logger
      ML_DB_HOST: db

networks:
  webnet:
```

Run:

```bash
$ docker-compose up
```

Then head over to [http://0.0.0.0:5050](http://0.0.0.0:5050).

## Contributing

To run on your local machine, you need to setup shop first.
Mailgun Logger requires a Postgres database using the following environment variables along with their defaults:

```elixir
# config/config.ex
config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER", "mailgun_logger_ci"),
  password: System.get_env("ML_DB_PASSWORD", "johndoe"),
  database: System.get_env("ML_DB_NAME", "mailgun_logger_ci_test"),
  hostname: System.get_env("ML_DB_HOST", "localhost"),
```

Either export your own enviroment variables or adhere to the defaults. Then, for convenience, run:

```bash
# runs mix local.hex, deps.get, compile; install dev certificates, make run (see below)
$ make install
```

which will install all dependencies and setup local dev https certificates using `phx.cert`.

Then you can run the project:
```bash
# runs `iex -S mix phx.server`
$ make run
```

All of the make targets are convenience wrappers around `mix`, feel free to run your own. If you are using your own environment variables, consider gathering them in an `.env` file and source that prior to running the make command:

```bash
# non POSIX uses `source` instead of `.`
$ . .env && make run
```

Then head over to [https://0.0.0.0:7000](https://0.0.0.0:7000).

## TODO

- [ ] check timestamp conversion!
- [x] clean up Makefile
- [x] add travis CI
- [x] add docker for CI
- [ ] test coverage
- [ ] provide generic logging agent? (no papertrail)

## License

This software is licensed under [the MIT license](LICENSE).

## About Jack + Joe

MailgunLogger is our very first open source project, and we are excited to get it out! We love open source and contributed to various tools over the years, and now we have our own! We use it ourselves as well.

Get to know our projects, get in touch. [jackjoe.be](https://jackjoe.be)
