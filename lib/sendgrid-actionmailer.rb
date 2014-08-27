require 'sendgrid-actionmailer/version'
require 'sendgrid-actionmailer/railtie' if defined? Rails

require 'sendgrid-ruby'

module SendGridActionMailer
  class DeliveryMethod
    def initialize(params)
      @client = SendGrid::Client.new do |c|
        c.api_user = params[:api_user]
        c.api_key  = params[:api_key]
      end
    end

    def deliver!(mail)
      email = SendGrid::Mail.new do |m|
        m.to      = mail[:to]
        m.from    = mail[:from]
        m.subject = mail[:subject]
        m.text    = mail[:text]
        m.html    = mail[:html]
      end
      @client.send(email)
    end
  end
end
