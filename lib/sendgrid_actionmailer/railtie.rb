module SendGridActionMailer
  class Railtie < Rails::Railtie
    initializer 'sendgrid_actionmailer.add_delivery_method' do
      ActiveSupport.on_load(:action_mailer) do
        ActionMailer::Base.add_delivery_method(:sendgrid_actionmailer, SendGridActionMailer::DeliveryMethod)
      end
    end
  end
end
