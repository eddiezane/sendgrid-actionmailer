# SendGrid ActionMailer

An ActionMailer adapter to send email using SendGrid's HTTPS Web API (instead of SMTP).

[![BuildStatus](https://travis-ci.org/eddiezane/sendgrid-actionmailer.svg?branch=master)](https://travis-ci.org/eddiezane/sendgrid-actionmailer)

## Installation

Add this line to your application's Gemfile:

    gem 'sendgrid-actionmailer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sendgrid-actionmailer
    

## Usage

Create a [SendGrid API Key](https://app.sendgrid.com/settings/api_keys) for your application. Then edit `config/application.rb` or `config/environments/$ENVIRONMENT.rb` and add/change the following to the ActionMailer configuration:

```ruby
config.action_mailer.delivery_method = :sendgrid_actionmailer
config.action_mailer.sendgrid_actionmailer_settings = {
  api_key: ENV['SENDGRID_API_KEY']
}
```

Normal ActionMailer usage will now transparently be sent using SendGrid's Web API.

### X-SMTPAPI

You may optionally set SendGrid's [X-SMTPAPI](https://sendgrid.com/docs/API_Reference/SMTP_API/index.html) header on messages to control SendGrid specific functionality. This header must be set to a JSON string.

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user)
    headers['X-SMTPAPI'] = {
      category: ['newuser']
    }.to_json

    mail(to: user.email, subject: 'Welcome to My Awesome Site')
  end
end
```

The following `X-SMTPAPI` options are supported:

- `filters`
- `category`
- `send_at`
- `send_each_at`
- `section`
- `sub`
- `asm_group_id`
- `unique_args`
- `ip_pool`

#### X-SMTPAPI Defaults

Default values for the `X-SMTPAPI` header may be set at different levels using ActionMailer's normal options for setting default headers. However, since `X-SMTPAPI` is treated as a single string value, it's important to note that default values at different levels will not get merged together. So if you override the `X-SMTPAPI` header at any level, you may need to repeat any default values at more specific levels.

Global defaults can be set inside `config/application.rb`:

```ruby
config.action_mailer.default_options = {
  'X-SMTPAPI' => {
    ip_pool: 'marketing_ip_pool'
  }.to_json
}
```

Per-mailer defaults can be set inside an ActionMailer class:

```ruby
class NewsletterMailer < ApplicationMailer
  default('X-SMTPAPI' => {
    category: ['newsletter'],

    # Assuming the above "config.action_mailer.default_options" global default
    # example, the default "ip_pool" value must be repeated here if you want
    # that default value to also apply to this specific mailer that's
    # specifying it's own default X-SMTPAPI value.
    ip_pool: 'marketing_ip_pool'
  }.to_json)
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sendgrid-actionmailer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
