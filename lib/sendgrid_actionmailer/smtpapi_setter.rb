module SendGridActionMailer
  class SmtpapiSetter
    def initialize(email, mail)
      @email = email
      @smtpapi_field = mail['X-SMTPAPI']
    end

    def set!
      return unless smtpapi_field && smtpapi_field.value
      set_categories
      set_unique_args
      set_ip_pool
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

    def set_unique_args
      (data['unique_args'] || {}).each do |key, value|
        email.smtpapi.add_unique_arg(key, value)
      end
    end

    def set_ip_pool
      email.smtpapi.set_ip_pool(data['ip_pool']) if data.key?('ip_pool')
    end
  end
end
