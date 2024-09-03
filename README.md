# Mailgun Logger

**BREAKING**

Since the 2305.1.0 release we are no longer saving the actual stored message (the raw data) as it has proven to put too much stress on the db without any added value. There is a config option `store_message` that, if set to `true` also requires an AWS config to be added. Then the raw messages will be stored in an S3 bucket.
Also, the `stored_message` data column should be regarded as deprecated and will be removed via a migration in a future release.

**Note**

Since version 2302.1.0 (Feb 2023) the database has switched from MySQL to PostgreSQL.

<div align="center" width="100%">
  <img src="./public/logo.svg" width="128" alt="" />
</div>

[![Build Status](https://app.travis-ci.com/jackjoe/mailgun_logger.svg?branch=master)](https://app.travis-ci.com/jackjoe/mailgun_logger)

Simple Mailgun log persistence in Phoenix/Elixir.

MailgunLogger is a simple admin tool that uses the Mailgun API to retrieves events on a regular basis from Mailgun - who only provide a limited time of event storage - and stores them inside a PostgreSQL database.
For efficiency and less complexity, it retrieves events for the last two days (free accounts offer up to three days of persistence) and then inserts everything. Only new events will pass the unique constraint on the db.

This is done because, as stated in the Mailgun docs, it is not guaranteed that for a given time period, all actual events will be ready, since some take time to get into the system although they already happened.

An AWS bucket can be configured to store the raw messages on S3.

See the docs for implementation details.

_**IMPORTANT**_

_This application is not affiliated, associated, authorized, endorsed by, or in any way officially connected with Mailgun, or any of its subsidiaries or its affiliates. The official Mailgun website can be found at [Mailgun](https://mailgun.com)._

_This is NOT meant as a replacement for the excellent online tooling provided by Mailgun. Just simple storage, that's it._

_Jack + Joe is not responsible for your use of this tool, neither for any persistence guarantees. Free comes at a price :)_

## Versioning

We use a simplified version numbering in the format of:

```
YYMM.MAJOR.MINOR
```

Where minor version bumps are consider to be hotfixes or small patches, major are bigger changes. For example:

```
2202.3.1 -> 2022, Februari, third major release, hotfix number 1.
```

Every month the major and minor versions are reset to zero, but start with one:

```
2202.4.0
2202.4.1
2202.5.0
2203.1.0
2203.2.0
2203.3.0
2203.3.1
2203.3.2
2203.4.0
2204.1.0
...
```

## Installation

MailgunLogger is available as a Docker image at [Docker](https://hub.docker.com/r/jackjoe/mailgun_logger).

### Variables

Following variables are available:

[Required]

- **ML_DB_USER**: database user
- **ML_DB_PASSWORD**: database password
- **ML_DB_NAME**: database name
- **ML_DB_HOST**: database host

[Optional]

- **ML_STORE_MESSAGES**: when true, persist messages to the S3 bucket described below, defaults to false
- **ML_PAGESIZE**: events per page
- **ML_LOG_LEVEL**: log level (info, debug, warn, ...)
- **MAILGUN_API_KEY**: to send the password reset email
- **MAILGUN_DOMAIN**: to send the password reset email
- **MAILGUN_FROM**: to send the password reset email
- **MAILGUN_REPLY_TO**: to send the password reset email
- **AWS_ACCESS_KEY_ID**: AWS key
- **AWS_SECRET_ACCESS_KEY**: AWS access key
- **AWS_REGION**: AWS region (e.g.: `eu-central-1`)
- **AWS_BUCKET**: AWS bucket
- **AWS_PORT**: AWS port (e.g.: 443)
- **AWS_SCHEME**: AWS scheme (e.g.: `https`)
- **AWS_ASSET_HOST**: AWS asset host name (e.g.: `http://files.yourdomain.com.s3.amazonaws.com/`)
- **AWS_HOST**: AWS host (e.g.: `s3.eu-central-1.amazonaws.com`)
- **RAW_PATH**: path from bucket root to store the messages on AWS

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
      - POSTGRES_PASSWORD=logger
      - POSTGRES_USER=logger
      - POSTGRES_DATABASE=mailgun_logger
    volumes:
      - db_data:/var/lib/postgresql/data

  web:
    image: jackjoe/mailgun_logger
    depends_on:
      - db
    entrypoint: ["./wait-for", "db:5432", "--", "./start.sh"]
    ports:
      - "5050:5050"
    networks:
      - webnet
    environment:
      - "ML_DB_USER=logger"
      - "ML_DB_PASSWORD=logger"
      - "ML_DB_NAME=mailgun_logger"
      - "ML_DB_HOST=db"
      - "MAILGUN_API_KEY=*****"
      - "MAILGUN_DOMAIN=m.mydomain.be"
      - "AWS_ACCESS_KEY_ID=******"
      - "AWS_SECRET_ACCESS_KEY=******"
      - "AWS_REGION=eu-central-1"
      - "AWS_BUCKET=*****"
      - "AWS_PORT=443"
      - "AWS_SCHEME=https://"
      - "AWS_ASSET_HOST=*****"
      - "AWS_HOST=s3.eu-central-1.amazonaws.com"
      - "RAW_PATH=mailgun_logger/messages"

networks:
  webnet:
    external: false

volumes:
  db_data: {}
```

Run:

```bash
$ docker-compose up
```

Then head over to [http://0.0.0.0:5050](http://0.0.0.0:5050).

### Postgresql tip

If you find yourself with many events in your database and a slow search, consider installing the [**pg_trm** extension](https://www.postgresql.org/docs/current/pgtrgm.html).
Adding an index on these 3 fields will give you a huge speed gain:

```mysql
CREATE EXTENSION pg_trgm;

CREATE INDEX events_recipient_gin_trgm_idx ON events USING gin (recipient gin_trgm_ops);
CREATE INDEX events_message_from_gin_trgm_idx ON events USING gin (message_from gin_trgm_ops);
CREATE INDEX events_message_subject_gin_trgm_idx ON events USING gin (message_subject gin_trgm_ops);
```

## Contributing

To run on your local machine, you need to setup shop first.
Mailgun Logger requires a PostgreSQL database using the following environment variables along with their defaults:

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

- [ ] test coverage
- [ ] provide generic logging agent? (no papertrail)

## License

This software is licensed under [the MIT license](LICENSE).

## About Jack + Joe

MailgunLogger is our very first open source project, and we are excited to get it out! We love open source and contributed to various tools over the years, and now we have our own! We use it ourselves as well.

Our [announcement article](https://jackjoe.be/articles/mailgun-logger).

Get to know our projects, get in touch. [jackjoe.be](https://jackjoe.be)
