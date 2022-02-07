## 2202.3.0

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
