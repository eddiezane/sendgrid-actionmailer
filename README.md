# SendGridRails

SendGrid support for Rails via ActionMailer.

## Installation

Add this line to your application's Gemfile:

    gem 'sendgrid-rails'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sendgrid-rails
    

## Usage

Edit your `config/environments/$ENVIRONMENT.rb` file and add/change the following to the ActionMailer configuration.

	  config.action_mailer.delivery_method = :sendgrid_rails

TODO: Add ActionMailer instructions.

TODO: Passing in credentials. Currently only works through environment variables.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sendgrid-rails/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
