# SendGrid ActionMailer

An ActionMailer adapter to send email using SendGrid's HTTPS Web API (instead of SMTP). Compatible with Rails 5 and Sendgrid API v3.

## Installation

Add this line to your application's Gemfile:

    gem 'sendgrid-actionmailer', github: 'eddiezane/sendgrid-actionmailer'

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

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body')```

## SendGrid Mail Extensions

The Mail functionality is extended to include additional attributes provided by the Sendgrid API.

[Sendgrid v3 API Documentation](https://sendgrid.com/docs/API_Reference/api_v3.html)

### template_id (string)
The id of a template that you would like to use. If you use a template that contains a subject and content (either text or html), you do not need to specify those at the personalizations nor message level.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', template_id: 'template_1')```

### sections (object)
An object of key/value pairs that define block sections of code to be used as substitutions.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', sections: {'%header%' => "<h1>Header</h1>"})```

### headers (object)
An object containing key/value pairs of header names and the value to substitute for them. You must ensure these are properly encoded if they contain unicode characters. Must not be one of the reserved headers.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', headers: {'X-CUSTOM-HEADER' => "foo"})```

### categories (array)
An array of category names for this message. Each category name may not exceed 255 characters.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', categories: ['marketing', 'sales'])```

### custom_args (object)
Values that are specific to the entire send that will be carried along with the email and its activity data. Substitutions will not be made on custom arguments, so any string that is entered into this parameter will be assumed to be the custom argument that you would like to be used. This parameter is overridden by personalizations[x].custom_args if that parameter has been defined. Total custom args size may not exceed 10,000 bytes.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', custom_args: {campaign: 'welcome'})```

### send_at (integer)
A unix timestamp allowing you to specify when you want your email to be delivered. This may be overridden by the personalizations[x].send_at parameter. You can't schedule more than 72 hours in advance. If you have the flexibility, it's better to schedule mail for off-peak times. Most emails are scheduled and sent at the top of the hour or half hour. Scheduling email to avoid those times (for example, scheduling at 10:53) can result in lower deferral rates because it won't be going through our servers at the same times as everyone else's mail.

### batch_id (string)
This ID represents a batch of emails to be sent at the same time. Including a batch_id in your request allows you include this email in that batch, and also enables you to cancel or pause the delivery of that batch. For more information, see [cancel_schedule_send](https://sendgrid.com/docs/API_Reference/Web_API_v3/cancel_schedule_send.html)

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', send_at: 1443636842, batch_id: 'batch1')```

### asm (object)
An object allowing you to specify how to handle unsubscribes.

#### group_id (integer) *required
The unsubscribe group to associate with this email.

#### groups_to_display (array[integer])
An array containing the unsubscribe groups that you would like to be displayed on the unsubscribe preferences page.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', asm: group_id: 99, groups_to_display: [4,5,6,7,8])```

### ip_pool_name (string)
The IP Pool that you would like to send this email from.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', ip_pool_name: 'marketing_ips')```

### mail_settings (object)
A collection of different mail settings that you can use to specify how you would like this email to be handled.

#### bcc (object)
This allows you to have a blind carbon copy automatically sent to the specified email address for every email that is sent.

##### enable (boolean)
Indicates if this setting is enabled.

##### email (string)
The email address that you would like to receive the BCC.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body', mail_settings: {bcc: {enable: true, email: 'bcc@example.com}})```

#### bypass_list_management (object)
Allows you to bypass all unsubscribe groups and suppressions to ensure that the email is delivered to every single recipient. This should only be used in emergencies when it is absolutely necessary that every recipient receives your email.

###### enable (boolean)
Indicates if this setting is enabled.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body',  mail_settings:{ bypass_list_management: { enable: true }})```

#### footer (object)
The default footer that you would like included on every email.

##### enable (boolean)
Indicates if this setting is enabled.

##### text (string)
The plain text content of your footer.

##### html (string)
The HTML content of your footer.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body',  mail_settings:{ footer: { enable: true, text: 'FOOTER', html: '<h1>FOOTER</h1>' }})```

#### sandbox_mode (object)
This allows you to send a test email to ensure that your request body is valid and formatted correctly.

##### enable (boolean)
Indicates if this setting is enabled.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body',  mail_settings:{ sandbox_mode: { enable: true }})```

#### spam_check (object)
This allows you to test the content of your email for spam.

##### enable (boolean)
Indicates if this setting is enabled.

##### threshold (integer)
The threshold used to determine if your content qualifies as spam on a scale from 1 to 10, with 10 being most strict, or most likely to be considered as spam.

##### post_to_url (string)
An Inbound Parse URL that you would like a copy of your email along with the spam report to be sent to.

```mail(to: 'example@email.com', subject: 'email subject', body: 'email body',  mail_settings:{ spam_check: {enable: true, threshold: 1, post_to_url: 'https://spamcatcher.sendgrid.com'}})```

