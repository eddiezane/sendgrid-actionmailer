require 'sendgrid_actionmailer/version'
require 'sendgrid_actionmailer/railtie' if defined? Rails
require 'sendgrid-ruby'

module SendGridActionMailer
  class DeliveryMethod
    include SendGrid

    attr_reader :client

    def initialize(params)
      # Actually it is...
      # https://github.com/sendgrid/ruby-http-client/blob/master/lib/ruby_http_client.rb
      @client = SendGrid::API.new(api_key: params.fetch(:api_key)).client
    end

    def deliver!(mail)
      sendgrid_mail = Mail.new.tap do |m|
        m.from = to_email(mail.smtp_envelope_from)
        m.subject = mail.subject

        # https://sendgrid.com/docs/Classroom/Send/v3_Mail_Send/personalizations.html
        m.add_personalization Personalization.new.tap do |p|
          m.to.each { |to| p.add_to(to_email(to)) }
          m.cc.each { |cc| p.add_cc(to_email(cc)) } unless m.cc.nil?
          m.bcc.each { |bcc| p.add_cc(to_email(bcc)) } unless m.cc.nil?
        end
      end

      case mail.mime_type
      when 'text/plain'
        sendgrid_mail.add_content = to_content(:plain, mail.body.decoded)
      when 'text/html'
        sendgrid_mail.add_content = to_content(:html, mail.body.decoded)
      when 'multipart/alternative', 'multipart/mixed', 'multipart/related'
        sendgrid_mail.add_content = to_content(:html, mail.html_part.decoded) if mail.html_part
        sendgrid_mail.add_content = to_content(:plain, mail.text_part.decoded) if mail.text_part

        mail.attachments.each do |part|
          sendgrid_mail.add_attachment(to_attachment(part))
        end
      end

      perform_send_request(sendgrid_mail)
    end

    private

    # type should be either :plain or :html
    def to_content(type, value)
      Content.new(type: "text/#{type}", value: value)
    end

    def to_email(str, **opts)
      Email.new(email: str, **opts)
    end

    def to_attachment(part)
      Attachment.new.tap do |a|
        a.content = part.body.decoded
        a.type = part.mime_type
        a.filename = part.filename

        disposition = get_disposition(part)
        a.disposition = disposition unless disposition.nil?

        has_content_id = part.header && part.has_content_id?
        a.content_id = part.header['content_id'] if has_content_id
      end
    end

    def get_disposition(message)
      return if message.header.nil?
      content_disp = message.header[:content_disposition]
      return unless content_disp.respond_to?(:disposition_type)
      content_disp.disposition_type
    end

    def perform_send_request(email)
      client._('send').post(request_body: email.to_json) # ლ(ಠ益ಠლ) that API
    end
  end
end
