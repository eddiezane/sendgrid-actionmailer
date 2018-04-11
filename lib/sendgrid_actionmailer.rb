require 'sendgrid_actionmailer/version'
require 'sendgrid_actionmailer/railtie' if defined? Rails
require 'sendgrid-ruby'

module SendGridActionMailer
  class DeliveryMethod
    SendgridDeliveryError = Class.new(StandardError)

    include SendGrid

    attr_reader :client, :raise_delivery_errors

    def initialize(params)
      # SendGrid::API is a wrapper of that...
      # https://github.com/sendgrid/ruby-http-client/blob/master/lib/ruby_http_client.rb
      @client = SendGrid::API.new(api_key: params.fetch(:api_key)).client
      @raise_delivery_errors = params.fetch(:raise_delivery_errors, false)
    end

    def deliver!(mail)
      sendgrid_mail = Mail.new.tap do |m|
        m.from = to_email(mail.smtp_envelope_from)
        m.subject = mail.subject
        # https://sendgrid.com/docs/Classroom/Send/v3_Mail_Send/personalizations.html
        m.add_personalization(to_personalizations(mail))
      end

      add_content(sendgrid_mail, mail)
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

    def to_personalizations(mail)
      Personalization.new.tap do |p|
        mail.to.each { |to| p.add_to(to_email(to)) }
        mail.cc.each { |cc| p.add_cc(to_email(cc)) } unless mail.cc.nil?
        mail.bcc.each { |bcc| p.add_cc(to_email(bcc)) } unless mail.cc.nil?
      end
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

    def add_content(sendgrid_mail, mail)
      case mail.mime_type
      when 'text/plain'
        sendgrid_mail.add_content(to_content(:plain, mail.body.decoded))
      when 'text/html'
        sendgrid_mail.add_content(to_content(:html, mail.body.decoded))
      when 'multipart/alternative', 'multipart/mixed', 'multipart/related'
        sendgrid_mail.add_content(to_content(:html, mail.html_part.decoded)) if mail.html_part
        sendgrid_mail.add_content(to_content(:plain, mail.text_part.decoded)) if mail.text_part

        mail.attachments.each do |part|
          sendgrid_mail.add_attachment(to_attachment(part))
        end
      end
    end

    def perform_send_request(email)
      result = client._('send').post(request_body: email.to_json) # ლ(ಠ益ಠლ) that API

      if result.status.start_with?('4')
        message = JSON.parse(r.body).fetch('errors').pop.fetch('message')
        full_message = "Sendgrid delivery failed with #{result.status} #{message}"

        raise_delivery_errors ? raise(SendgridDeliveryError, full_message) : warn(full_message)
      end

      result
    end
  end
end
