# Change Log

## 0.2.1 - 2016-04-26

### Fixed

- Fix handling of multipart/related inline attachments.

## 0.2.0 - 2016-04-25

### Added

- Support for `reply_to` and `date` options.

### Fixed

- Fix sending when multiple `X-SMTPAPI` headers are set.

## 0.1.1 - 2016-04-25

### Fixed

- Fix file attachments.

## 0.1.0 - 2016-04-23

### Added

- Support for `cc` and `bcc` options.
- Support the `X-SMTPAPI` header.

### Changed

- Compatibility with `sendgrid-ruby` v1.0.
- Compatibility with `mail` v2.6.

### Fixed

- Fix `From` addresses with display names.
