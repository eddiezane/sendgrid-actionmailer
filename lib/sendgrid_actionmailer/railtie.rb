module SendGridActionMailer
  class Railtie < Rails::Railtie
    initializer 'sendgrid_actionmailer.add_delivery_method', before: 'action_mailer.set_configs' do
      ActionMailer::Base.add_delivery_method(:sendgrid_actionmailer, SendGridActionMailer::DeliveryMethod)
    end
  end
end
