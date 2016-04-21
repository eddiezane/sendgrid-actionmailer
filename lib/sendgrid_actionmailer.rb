require 'sendgrid_actionmailer/version'
require 'sendgrid_actionmailer/railtie' if defined? Rails

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
      from = mail[:from].addrs.first

      email = SendGrid::Mail.new do |m|
        m.to        = mail[:to].addresses
        m.from      = from.address
        m.from_name = from.display_name
        m.subject   = mail.subject
      end

      smtpapi = mail['X-SMTPAPI']
      if smtpapi && smtpapi.value
        begin
          data = JSON.parse(smtpapi.value)
          Array(data['category']).each do |category|
            email.smtpapi.add_category(category)
          end
        rescue JSON::ParserError
          raise ArgumentError, "X-SMTPAPI is not JSON: #{smtpapi.value}"
        end
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
