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

To take advantage of the SendGrid SMTP API using this gem, set the `X-SMTPAPI` header of
the Mail object.

#### Category

Tag emails with a <a href="https://sendgrid.com/docs/API_Reference/SMTP_API/categories.html">category</a>.

```ruby
class PromoMailer < ActionMailer::Base
  def weekly_sales(recipient)
    mail(
      to: recipient,
      subject: 'Big Weekly Sales!',
      'X-SMTPAPI' => { category: 'promo' }.to_json
    )
  end
end
```

#### Unique Arguments

Add 1 or more <a href="https://sendgrid.com/docs/API_Reference/SMTP_API/unique_arguments.html">unique arguments</a>
to add context to tracking.

```ruby
class PromoMailer < ActionMailer::Base
  def weekly_sales(recipient)
    mail(
      to: recipient,
      subject: 'Big Weekly Sales!',
      'X-SMTPAPI' => { unique_args: { user: recipient, promo: 'weekly' } }.to_json
    )
  end
end
```

#### IP Pool

Select which <a href="https://sendgrid.com/docs/API_Reference/Web_API_v3/IP_Management/ip_pools.html">IP pool</a>
the email should be delivered from. Note: the named IP pool must be set up before the
email is delivered.

```ruby
class PromoMailer < ActionMailer::Base
  default('X-SMTPAPI' => { ip_pool: 'promotions' }.to_json)

  def weekly_sales(recipient)
    mail(
      to: recipient,
      subject: 'Big Weekly Sales!'
    )
  end
end
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/sendgrid-actionmailer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
