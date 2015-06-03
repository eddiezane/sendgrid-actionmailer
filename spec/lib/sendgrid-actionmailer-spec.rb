require 'sendgrid-actionmailer'

module SendGridActionMailer
  describe DeliveryMethod do
    describe '#initialize' do
      subject(:delivery) do
        DeliveryMethod.new(api_user: 'user', api_key: 'key')
      end

      it 'configures the client API user' do
        expect(delivery.client.api_user).to eq('user')
      end

      it 'configures the client API key' do
        expect(delivery.client.api_key).to eq('key')
      end
    end
  end
end
