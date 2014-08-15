require 'sendgrid-rails/version'

require 'sendgrid-ruby'

module SendGridRails
  class DeliveryMethod
    def initialize(params = {})
      @client = SendGrid::Client.new(params)
    end

    def deliver!(mail)
      @client.send(mail)
    end
  end
end
