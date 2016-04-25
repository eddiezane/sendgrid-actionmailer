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
      attachment_tempfiles = []
      from = mail[:from].addrs.first

      email = SendGrid::Mail.new do |m|
        m.to        = mail[:to].addresses
        m.cc        = mail[:cc].addresses  if mail[:cc]
        m.bcc       = mail[:bcc].addresses if mail[:bcc]
        m.from      = from.address
        m.from_name = from.display_name
        m.reply_to  = mail[:reply_to].addresses.first if mail[:reply_to]
        m.date      = mail[:date].to_s if mail[:date]
        m.subject   = mail.subject
      end

      smtpapi = mail['X-SMTPAPI']
      if smtpapi && smtpapi.value
        begin
          data = JSON.parse(smtpapi.value)

          if data['filters']
            email.smtpapi.set_filters(data['filters'])
          end

          if data['category']
            email.smtpapi.set_categories(data['category'])
          end

          if data['send_at']
            email.smtpapi.set_send_at(data['send_at'])
          end

          if data['send_each_at']
            email.smtpapi.set_send_each_at(data['send_each_at'])
          end

          if data['section']
            email.smtpapi.set_sections(data['section'])
          end

          if data['sub']
            email.smtpapi.set_substitutions(data['sub'])
          end

          if data['asm_group_id']
            email.smtpapi.set_asm_group(data['asm_group_id'])
          end

          if data['unique_args']
            email.smtpapi.set_unique_args(data['unique_args'])
          end

          if data['ip_pool']
            email.smtpapi.set_ip_pool(data['ip_pool'])
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
          # Create a tempfile with the same file extension as the real file
          # for sendgrid-ruby's mime type lookups.
          t = Tempfile.new(["sendgrid-actionmailer", File.extname(a.filename)])
          t.binmode
          t.write(a.read)
          t.flush
          t.rewind
          email.add_attachment(t, a.filename)
          attachment_tempfiles << t
        end
      end

      client.send(email)
    ensure
      # Close and delete the attachment tempfiles after the e-mail has been
      # sent.
      attachment_tempfiles.each do |file|
        file.close
        file.unlink
      end
    end
  end
end
