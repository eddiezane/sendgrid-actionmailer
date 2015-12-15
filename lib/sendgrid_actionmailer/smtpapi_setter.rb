module SendGridActionMailer
  class SmtpapiSetter
    def initialize(email, mail)
      @email = email
      @smtpapi_field = mail['X-SMTPAPI']
    end

    def set!
      return unless smtpapi_field && smtpapi_field.value
      set_categories
    rescue JSON::ParserError
      raise ArgumentError, "X-SMTPAPI is not JSON: #{smtpapi_field.value}"
    end

    private

    attr_reader :email, :smtpapi_field

    def data
      @data ||= JSON.parse(smtpapi_field.value)
    end

    def set_categories
      Array(data['category']).each do |category|
        email.smtpapi.add_category(category)
      end
    end
  end
end
