module SendGridRails
  class Railtie < Rails::Railtie
    initializer 'sendgrid_rails.add_delivery_method' do
      ActiveSupport.on_load(:action_mailer) do
        ActionMailer::Base.add_delivery_method(:sendgrid_rails, SendGridRails::DeliveryMethod)
      end
    end
  end
end
