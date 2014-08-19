module SendGridRails
  class Railtie < Rails::Railtie
    initializer 'sendgrid_rails.add_delivery_method', before: 'action_mailer.set_configs' do
      ActionMailer::Base.add_delivery_method(:sendgrid_rails, SendGridRails::DeliveryMethod)
    end
  end
end
