# Mailgun Logger

**BREAKING**

Since the 2305.1.0 release we are no longer saving the actual stored message (the raw data) as it has proven to put too much stress on the db without any added value. There is a config option `store_message` that, if set to `true` also requires an AWS config to be added. Then the raw messages will be stored in an S3 bucket.
Also, the `stored_message` data column should be regarded as deprecated and will be removed via a migration in a future release.

**Note**

Since version 2302.1.0 (Feb 2023) the database has switched from MySQL to PostgreSQL.

<div align="center" width="100%">
  <img src="./public/logo.svg" width="128" alt="" />
</div>

Simple Mailgun log persistence in Phoenix/Elixir.

MailgunLogger is a simple admin tool that uses the Mailgun API to retrieves events on a regular basis from Mailgun - who only provide a limited time of event storage - and stores them inside a PostgreSQL database.
For efficiency and less complexity, it retrieves events for the last two days (free accounts offer up to three days of persistence) and then inserts everything. Only new events will pass the unique constraint on the db.

This is done because, as stated in the Mailgun docs, it is not guaranteed that for a given time period, all actual events will be ready, since some take time to get into the system although they already happened.

An AWS bucket can be configured to store the raw messages on S3.

See the docs for implementation details.

## Features

- **Events**: filter on event type, sender, recipient, subject, account, time range (UTC) and message ID. Click an event type, sender or recipient in the list to filter on it. Failed events show the failure reason. Choose 50, 100 or 250 events per page, and export the current filters as CSV (at most 100 000 rows).
- **Keyboard**: `/` focuses the search, `j` and `k` move between events, `Enter` opens the selected event and `Esc` leaves a field.
- **Event detail**: the timeline of all events of the message and the raw JSON from Mailgun, with a copy button.
- **Stats**: counts and rates (delivered, failed and opened) for the last 24 hours, 7 days or 30 days, compared with the period before. A chart per hour or day, the top failure reasons and the top failing recipient domains. Every number links to the matching events.
- **Account health**: each account shows when the last run was and its result, for example `401: unauthorized` for a wrong API key. "Trigger Run" starts a run immediately.

_**IMPORTANT**_

_This application is not affiliated, associated, authorized, endorsed by, or in any way officially connected with Mailgun, or any of its subsidiaries or its affiliates. The official Mailgun website can be found at [Mailgun](https://mailgun.com)._

_This is NOT meant as a replacement for the excellent online tooling provided by Mailgun. Just simple storage, that's it._

_Jack + Joe is not responsible for your use of this tool, neither for any persistence guarantees. Free comes at a price :)_

## Requirements

- Elixir ~> 1.17
- Phoenix ~> 1.8
- PostgreSQL

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

The application reads the following variables at boot, see `config/runtime.exs`:

[Required]

- **ML_DB_USER**: database user
- **ML_DB_PASSWORD**: database password
- **ML_DB_NAME**: database name
- **ML_DB_HOST**: database host
- **SECRET_KEY_BASE**: secret key base for Phoenix (required for releases)
- **HOST**: application host (e.g. `localhost`)
- **PORT**: application port (default: `5050`)

[Optional]

- **ML_DB_PORT**: database port (default: `5432`)
- **ML_PAGESIZE**: events per page (default: `50`)
- **ML_STORE_MESSAGES**: when true, persist messages to the S3 bucket described below, defaults to false
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
  -e "SECRET_KEY_BASE=your-secret-key-base" \
  -e "HOST=localhost" \
  --name mailgun_logger jackjoe/mailgun_logger
```

### Docker Compose

With the following `docker-compose.yml`:

```yml
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
      - "SECRET_KEY_BASE=generate-a-secret-key-base"
      - "HOST=localhost"
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

```sql
CREATE EXTENSION pg_trgm;

CREATE INDEX events_recipient_gin_trgm_idx ON events USING gin (recipient gin_trgm_ops);
CREATE INDEX events_message_from_gin_trgm_idx ON events USING gin (message_from gin_trgm_ops);
CREATE INDEX events_message_subject_gin_trgm_idx ON events USING gin (message_subject gin_trgm_ops);
```

## Contributing

To run on your local machine, you need to setup shop first.
Mailgun Logger requires a PostgreSQL database using the following environment variables along with their defaults:

```elixir
# config/dev.exs
config :mailgun_logger, MailgunLogger.Repo,
  username: System.get_env("ML_DB_USER", "postgres"),
  password: System.get_env("ML_DB_PASSWORD", "postgres"),
  database: System.get_env("ML_DB_NAME", "mailgun_logger_dev"),
  hostname: System.get_env("ML_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("ML_DB_PORT", "5432"))
```

The tests use the same variables, except `ML_DB_NAME`: the test database is always `mailgun_logger_test`.

Either export your own enviroment variables or adhere to the defaults. Then, for convenience, run:

```bash
# runs mix local.hex, deps.get, compile; install dev certificates, make run (see below)
$ make install
```

which will install all dependencies and setup local dev https certificates using `phx.cert`.

Next you need to run the migrations and seeder:

```bash
$ source .env && mix ecto.migrate
$ source .env && mix run priv/repo/seeds.exs
```

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

Then head over to [https://localhost:7070](https://localhost:7070).

In development, esbuild builds `priv/static/assets/js/app.js` and rebuilds it on every change. That file is not in git: the Docker build runs `mix assets.deploy`, which builds a minified bundle and digests the static files.

## TODO

- [ ] test coverage
- [ ] provide generic logging agent? (no papertrail)

## License

This software is licensed under [the MIT license](LICENSE).

## About Jack + Joe

MailgunLogger is our very first open source project, and we are excited to get it out! We love open source and contributed to various tools over the years, and now we have our own! We use it ourselves as well.

Our [announcement article](https://jackjoe.be/articles/mailgun-logger).

Get to know our projects, get in touch. [jackjoe.be](https://jackjoe.be)
