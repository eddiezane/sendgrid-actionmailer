require 'sendgrid-actionmailer/version'
require 'sendgrid-actionmailer/railtie' if defined? Rails

require 'tempfile'

require 'sendgrid-ruby'

module SendGridActionMailer
  class DeliveryMethod
    attr_reader :client

    def initialize(params)
      @client = SendGrid::Client.new do |c|
        c.api_user = params[:api_user]
        c.api_key  = params[:api_key]
      end
    end

    def deliver!(mail)
      email = SendGrid::Mail.new do |m|
        m.to      = mail[:to].addresses
        m.from    = mail[:from].value
        m.subject = mail.subject
      end

      # TODO: This is pretty ugly
      case mail.mime_type
      when 'text/plain'
        # Text
        email.text = mail.body.decoded
      when 'text/html'
        # HTML
        email.html = mail.body.decoded
      when 'multipart/alternative', 'multipart/mixed'
        email.html = mail.html_part.decoded if mail.html_part
        email.text = mail.text_part.decoded if mail.text_part

        # This needs to be done better
        mail.attachments.each do |a|
          begin
            t = Tempfile.new("sendgrid-actionmailer")
            t.binmode
            t.write(a.read)
            t.flush
            email.add_attachment(t, a.filename)
          ensure
            t.close
            t.unlink
          end
        end
      end

      client.send(email)
    end
  end
end
