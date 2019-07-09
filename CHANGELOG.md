# Change Log

## 2.4.0 - 2019-07-9

### Changed

- Compatibility with `sendgrid-ruby` v6.0.

## 2.3.0 - 2019-4-10

### Fixes

- No asm substitutions if template_id present

## 2.2.1 - 2019-1-4

### Fixes

- Fix Travis

## 2.2.0 - 2018-11-23

### Fixes

- Update Readme

## 2.1.0 - 2018-11-20

### Fixes

- Substiutions and dynamic_template_data should be compatible.


## 2.0.0 - 2018-08-15

### Changed

- Compatibility with `sendgrid-ruby` v5.0.

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
