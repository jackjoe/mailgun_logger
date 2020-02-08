# Mailgun Logger

Simple admin tool to get Mailgun persistence ad infinite.

MailgunLogger is a simple admin tool that uses the Mailgun API to retrieves events on a regular basis from Mailgun - who only provide a limited time of event storage - and stores them inside a Postgres database.
For efficiency and less complexity, it retrieves events for the last two days (free accounts offer up to three days of persistance) and then inserts everything. Only new events will pass the unique constraint on the db.

This is done because, as stated in the Mailgun docs, it is not guaranteed that for a given time period, all actual events will be ready, since some take time to get into the system allthough they already happened.

See the docs for implementation details.

_**IMPORTANT**_

_This application is not affiliated, associated, authorized, endorsed by, or in any way officially connected with Mailgun, or any of its subsidiaries or its affiliates. The official Mailgun website can be found at [mailgun](https://mailgun.com)._

_Jack + Joe is not responsible for your use of this tool, neither for any persistance guarantees. Free comes at a price :)_

## Installation

MailgunLogger is available as a Docker image at [docker_url]. To run it:

```
$ do this
$ do that
```

## Requirements

## Contributing

To run on your local machine, you need to setup shop first:

```
$ make setup
```

Then you can run the project:
```
$ make run
```

## TODO

- [ ] check timestamp conversion!
- [ ] clean up Makefile
- [ ] add to travis / docker for CI
- [ ] cleanup user is_test
- [ ] test coverage
- [ ] provide generic logging agent? (no papertrail)

## License

This software is licensed under [the MIT license](LICENSE.md).

## About Jack + Joe

MailgunLogger is our very first open source project, and we are excited to get it out! We love open source and contributed to various tools over the years, and now we have our own!

Get to know our projects, get in touch. [jackjoe.be](https://jackjoe.be)
