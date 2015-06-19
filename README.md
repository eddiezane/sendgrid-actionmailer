# SendGrid ActionMailer

SendGrid support for Rails via ActionMailer.

[![BuildStatus](https://travis-ci.org/eddiezane/sendgrid-actionmailer.svg?branch=master)](https://travis-ci.org/eddiezane/sendgrid-actionmailer)

## Installation

Add this line to your application's Gemfile:

    gem 'sendgrid-actionmailer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sendgrid-actionmailer
    

## Usage

Edit your `config/environments/$ENVIRONMENT.rb` file and add/change the following to the ActionMailer configuration.

	  config.action_mailer.delivery_method = :sendgrid_actionmailer
	  config.action_mailer.sendgrid_actionmailer_settings = {api_user: ENV['SENDGRID_USERNAME'], api_key: ENV['SENDGRID_PASSWORD']}

TODO: Add ActionMailer instructions.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sendgrid-actionmailer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
