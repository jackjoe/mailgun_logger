## 2305.7.0 (2023-06-30)

- Drastically improve query speed by removing a join

## 2305.6.2 (2023-06-30)

- Bump dependencies

## 2305.6.1 (2023-06-15)

- Ignore bgcolor attr in original event html

## 2305.6.0 (2023-06-09)

- Improve redirects
- Promote event listing to new home page (for faster loading)

## 2305.5.0 (2023-06-09)

- Add logger to Papertrail

## 2305.4.1 (2023-05-24)

- Provide env config option for the db port

## 2305.4.0 (2023-05-08)

- Cursor based pagination using Flop

## 2305.3.0 (2023-05-08)

- Add attachment info on the event detail page

## 2305.2.0 (2023-05-08)

- Update packages

## 2305.1.0 (2023-05-02)

**BREAKING**

In this release, we are no longer saving the actual stored message (the raw data) as it has proven to be too much stress on the db without any added value. There is a config option `store_message` that, if set to `true` also requires an AWS config to be added. Then the raw messages will be stored in an S3 bucket.
Also, the `stored_message` data column should be regarded as deprecated and will be removed via a migration in a future release.

- Add AWS config and option to store the raw message there.

## 2302.1.1 (2023-02-27)

- Port `DATE_FORMAT` to PostgreSQL

## 2302.1.0 (2023-02-17)

- Migrate from MySQL to PostgreSQL

## 2209.4.0 (2022-09-12)

- Update event detail page to extract possible error message better
- Add stats and graphs to the dashboard

## 2209.3.0 (2022-09-08)

- Basic user management

## 2209.2.1 (2022-09-08)

- HOTFIX: uncomment important code (from testing)

## 2209.2.0 (2022-09-08)

- Fix password reset flow
- Update readme with Mailgun API key info
- Add send/recv output column to indicate if a message was received via an inbound route or a regular outgoing send

## 2209.1.0 (2022-09-07)

- Load internal Mailgun API key from runtime config

## 2202.4.4 (2022-07-21)

- Fix index length on events
- Fix unhandled error when using an invalid api key
- Release new version on our national holiday! 🇧🇪

## 2202.4.2 (2022-07-18)

- Increase `message_to` field size

## 2202.4.1

- Fix stored message slow query

## 2202.4.0

- Fix version numbering
- Fix old layout code in the setup template

## 2022.2.0

- Add account filter to the search

## 2021.9.3

- Improve detail page styling
- Optimize events query

## 0.3.0 (2021-07-20)

- Tweak styling
- Store actual sent messages and provide preview in the UI

## 0.2.0 (2021-05-15)

- Password reset flow

## 0.1.2 (2021-04-14)

- Upgrade to Phoenix 1.5.
- Output error type in red and delivered mails in green.

## 0.1.1 (2021-02-16)

- Fix database connection timeout when inserting a large amount of events with `Repo.transaction`, bu adding a infinit timeout to it.

## 0.1.0 (2021-02-03)

**POSSIBLY BREAKING! (Possibly, but not surely, so no 1.0.0 yet!)**

We had to alter the unique index (stupid mistake... more tests, anyone ;) ?). We do have a migration but it could be possible you have to alter that index yourself. It should be fairly easy, just add a unique constraint on the `accounts` table for columsn `api_key` and `domain`.

- fixed unique constraint for API key and domain on accounts. ([#7][i7])

## 0.0.5 (2020-10-14)

- removed Timex dependency

## 0.0.3 (2020-02-08)

We are on Github!

### Added

- Setup flow

[i7]: https://github.com/jackjoe/mailgun_logger/issues/7
