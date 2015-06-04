require 'mail'
require 'sendgrid-actionmailer'

module SendGridActionMailer
  describe DeliveryMethod do
    subject(:mailer) do
      DeliveryMethod.new(api_user: 'user', api_key: 'key')
    end

    class TestClient
      attr_reader :sent_mail

      def send(mail)
        @sent_mail = mail
      end
    end

    describe '#initialize' do
      it 'configures the client API user' do
        expect(mailer.client.api_user).to eq('user')
      end

      it 'configures the client API key' do
        expect(mailer.client.api_key).to eq('key')
      end
    end

    describe '#deliver!' do
      let(:client) { TestClient.new }
      let(:mail) do
        Mail.new(
          to:      'test@sendgrid.com',
          from:    'taco@cat.limo',
          subject: 'Hello, world!'
        )
      end

      before { SendGrid::Client.stub(:new).and_return(client) }

      it 'sets to' do
        mailer.deliver!(mail)
        expect(client.sent_mail.to).to eq(%w[test@sendgrid.com])
      end

      it 'sets from' do
        mailer.deliver!(mail)
        expect(client.sent_mail.from).to eq('taco@cat.limo')
      end

      it 'sets subject' do
        mailer.deliver!(mail)
        expect(client.sent_mail.subject).to eq('Hello, world!')
      end
    end
  end
end
