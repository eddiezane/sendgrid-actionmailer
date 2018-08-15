# SendGrid ActionMailer

An ActionMailer adapter to send email using SendGrid's HTTPS Web API (instead of SMTP).

> THIS FORK IS AIMED TO PROVIDE COMPATABILITY WITH RAILS v5 AND SENDGRID v5. IT'S EXPERIMENTAL AND HAVE NO TESTS YET.

## Installation

Add this line to your application's Gemfile:

    gem 'sendgrid-actionmailer', github: 'dikond/sendgrid-actionmailer', branch: 'sendgrid_5'

## Usage

Create a [SendGrid API Key](https://app.sendgrid.com/settings/api_keys) for your application. Then edit `config/application.rb` or `config/environments/$ENVIRONMENT.rb` and add/change the following to the ActionMailer configuration:

```ruby
config.action_mailer.delivery_method = :sendgrid_actionmailer
config.action_mailer.sendgrid_actionmailer_settings = {
  api_key: ENV['SENDGRID_API_KEY'],
  raise_delivery_errors: true
}
```

Normal ActionMailer usage will now transparently be sent using SendGrid's Web API.
