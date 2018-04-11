# SendGrid ActionMailer

An ActionMailer adapter to send email using SendGrid's HTTPS Web API (instead of SMTP).

> THIS FORK IS AIMED TO PROVIDE WITH RAILS v5 AND SENDGRID v5 COMPATABILITY. IT'S EXPERIMENTAL AND HAVE NOT TESTS YET.

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

## Contributing

1. Fork it ( https://github.com/eddiezane/sendgrid-actionmailer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
