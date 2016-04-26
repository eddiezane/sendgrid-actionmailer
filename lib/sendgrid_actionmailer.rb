require 'sendgrid_actionmailer/version'
require 'sendgrid_actionmailer/railtie' if defined? Rails

require 'fileutils'
require 'tmpdir'

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
      attachment_temp_dirs = []
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

      # If multiple X-SMTPAPI headers are present on the message, then pick the
      # first one. This may happen when X-SMTPAPI is set with defaults at the
      # class-level (using defaults()), as well as inside an individual method
      # (using headers[]=). In this case, we'll defer to the more specific
      # header set in the individual method, which is the first header
      # (somewhat counter-intuitively:
      # https://github.com/rails/rails/issues/15912).
      if(smtpapi.kind_of?(Array))
        smtpapi = smtpapi.first
      end

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
      when 'multipart/alternative', 'multipart/mixed', 'multipart/related'
        email.html = mail.html_part.decoded if mail.html_part
        email.text = mail.text_part.decoded if mail.text_part

        mail.attachments.each do |a|
          # Write the attachment into a temporary location, since sendgrid-ruby
          # expects to deal with files.
          #
          # We write to a temporary directory (instead of a tempfile) and then
          # use the original filename inside there, since sendgrid-ruby's
          # add_content method pulls the filename from the path (so tempfiles
          # would lead to random filenames).
          temp_dir = Dir.mktmpdir('sendgrid-actionmailer')
          attachment_temp_dirs << temp_dir
          temp_path = File.join(temp_dir, a.filename)
          File.open(temp_path, 'wb') do |file|
            file.write(a.read)
          end

          if(mail.mime_type == 'multipart/related' && a.header[:content_id])
            email.add_content(temp_path, a.header[:content_id].field.content_id)
          else
            email.add_attachment(temp_path, a.filename)
          end
        end
      end

      client.send(email)
    ensure
      # Close and delete the attachment tempfiles after the e-mail has been
      # sent.
      attachment_temp_dirs.each do |dir|
        FileUtils.remove_entry_secure(dir)
      end
    end
  end
end
