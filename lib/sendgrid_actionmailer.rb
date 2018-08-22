require 'sendgrid_actionmailer/version'
require 'sendgrid_actionmailer/railtie' if defined? Rails
require 'sendgrid-ruby'

module SendGridActionMailer
  class DeliveryMethod
    # TODO: use custom class to customer excpetion payload
    SendgridDeliveryError = Class.new(StandardError)

    include SendGrid

    DEFAULTS = {
      raise_delivery_errors: false,
    }

    attr_accessor :settings

    def initialize(**params)
      self.settings = DEFAULTS.merge(params)
    end

    def deliver!(mail)
      sendgrid_mail = Mail.new.tap do |m|
        m.from = to_email(mail.from)
        m.reply_to = to_email(mail.reply_to)
        m.subject = mail.subject
        # https://sendgrid.com/docs/Classroom/Send/v3_Mail_Send/personalizations.html
        m.add_personalization(to_personalizations(mail))
      end

      add_content(sendgrid_mail, mail)
      add_send_options(sendgrid_mail, mail)
      add_mail_settings(sendgrid_mail, mail)
      add_tracking_settings(sendgrid_mail, mail)

      response = perform_send_request(sendgrid_mail)

      settings[:return_response] ? response : self
    end

    private

    def client
      @client ||= SendGrid::API.new(api_key: settings.fetch(:api_key)).client
    end

    # type should be either :plain or :html
    def to_content(type, value)
      Content.new(type: "text/#{type}", value: value)
    end

    def to_email(input)
      to_emails(input).first
    end

    def to_emails(input)
      if input.is_a?(String)
        [Email.new(email: input)]
      elsif input.is_a?(::Mail::AddressContainer) && !input.instance_variable_get('@field').nil?
        input.instance_variable_get('@field').addrs.map do |addr| # Mail::Address
          Email.new(email: addr.address, name: addr.name)
        end
      elsif input.is_a?(::Mail::AddressContainer)
        input.map do |addr|
          Email.new(email: addr)
        end
      elsif input.is_a?(::Mail::StructuredField)
        [Email.new(email: input.value)]
      elsif input.nil?
        []
      else
        puts "unknown type #{input.class.name}"
      end
    end

    def to_personalizations(mail)
      Personalization.new.tap do |p|
        to_emails(mail.to).each { |to| p.add_to(to) }
        to_emails(mail.cc).each { |cc| p.add_cc(cc) }
        to_emails(mail.bcc).each { |bcc| p.add_bcc(bcc) }
      end
    end

    def to_attachment(part)
      Attachment.new.tap do |a|
        a.content = Base64.strict_encode64(part.body.decoded)
        a.type = part.mime_type
        a.filename = part.filename

        disposition = get_disposition(part)
        a.disposition = disposition unless disposition.nil?

        has_content_id = part.header && part.has_content_id?
        a.content_id = part.header['content_id'].value if has_content_id
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
        sendgrid_mail.add_content(to_content(:plain, mail.text_part.decoded)) if mail.text_part
        sendgrid_mail.add_content(to_content(:html, mail.html_part.decoded)) if mail.html_part

        mail.attachments.each do |part|
          sendgrid_mail.add_attachment(to_attachment(part))
        end
      end
    end

    def add_send_options(sendgrid_mail, mail)
      if mail['template_id']
         sendgrid_mail.template_id = mail['template_id'].to_s
      end
      if mail['sections']
        JSON.parse(mail['sections'].value.gsub(/:*\"*([\%a-zA-Z0-9_-]*)\"*(( *)=>\ *)/) { "\"#{$1}\":" }).each do |key, value|
          sendgrid_mail.add_section(Section.new(key: key, value: value))
        end
      end
      if mail['headers']
        JSON.parse(mail['headers'].value.gsub(/:*\"*([\%a-zA-Z0-9_-]*)\"*(( *)=>\ *)/) { "\"#{$1}\":" }).each do |key, value|
          sendgrid_mail.add_header(Header.new(key: key, value: value))
        end
      end
      if mail['categories']
        mail['categories'].value.split(",").each do |value|
          sendgrid_mail.add_category(Category.new(name: value.strip))
        end
      end
      if mail['custom_args']
        JSON.parse(mail['custom_args'].value.gsub(/:*\"*([\%a-zA-Z0-9_-]*)\"*(( *)=>\ *)/) { "\"#{$1}\":" }).each do |key, value|
          sendgrid_mail.add_custom_arg(CustomArg.new(key: key, value: value))
        end
      end
      if mail['send_at'] && mail['batch_id']
        sendgrid_mail.send_at = mail['send_at'].value.to_i
        sendgrid_mail.batch_id= mail['batch_id'].to_s
      end
      if mail['asm']
        asm = JSON.parse(mail['asm'].value.gsub(/:*\"*([\%a-zA-Z0-9_-]*)\"*(( *)=>\ *)/) { "\"#{$1}\":" }, symbolize_names: true)
        asm =  asm.delete_if { |key, value| !key.to_s.match(/(group_id)|(groups_to_display)/) }
        if asm[:group_id]
          sendgrid_mail.asm = ASM.new(asm)
        end
      end
      if mail['ip_pool_name']
        sendgrid_mail.ip_pool_name = mail['ip_pool_name'].to_s
      end
    end

    def add_mail_settings(sendgrid_mail, mail)
      if mail['mail_settings']
        settings = JSON.parse(mail['mail_settings'].value.gsub(/:*\"*([\%a-zA-Z0-9_-]*)\"*(( *)=>\ *)/) { "\"#{$1}\":" }, symbolize_names: true)
        sendgrid_mail.mail_settings = MailSettings.new.tap do |m|
          if settings[:bcc]
            m.bcc = BccSettings.new(settings[:bcc])
          end
          if settings[:bypass_list_management]
            m.bypass_list_management = BypassListManagement.new(settings[:bypass_list_management])
          end
          if settings[:footer]
            m.footer = Footer.new(settings[:footer])
          end
          if settings[:sandbox_mode]
            m.sandbox_mode = SandBoxMode.new(settings[:sandbox_mode])
          end
          if settings[:spam_check]
            m.spam_check = SpamCheck.new(settings[:spam_check])
          end
        end
      end
    end

    def add_tracking_settings(sendgrid_mail, mail)
      if mail['tracking_settings']
        settings = JSON.parse(mail['tracking_settings'].value.gsub(/:*\"*([\%a-zA-Z0-9_-]*)\"*(( *)=>\ *)/) { "\"#{$1}\":" }, symbolize_names: true)
        sendgrid_mail.tracking_settings = TrackingSettings.new.tap do |t|
          if settings[:click_tracking]
            t.click_tracking = ClickTracking.new(settings[:click_tracking])
          end
          if settings[:open_tracking]
            t.open_tracking = OpenTracking.new(settings[:open_tracking])
          end
          if settings[:subscription_tracking]
            t.subscription_tracking = SubscriptionTracking.new(settings[:subscription_tracking])
          end
          if settings[:ganalytics]
            t.ganalytics = Ganalytics.new(settings[:ganalytics])
          end
        end
      end
    end

    def perform_send_request(email)
      result = client.mail._('send').post(request_body: email.to_json) # ლ(ಠ益ಠლ) that API

      if result.status_code && result.status_code.start_with?('4')
        message = JSON.parse(result.body).fetch('errors').pop.fetch('message')
        full_message = "Sendgrid delivery failed with #{result.status_code} #{message}"

        settings[:raise_delivery_errors] ? raise(SendgridDeliveryError, full_message) : warn(full_message)
      end

      result
    end
  end
end
