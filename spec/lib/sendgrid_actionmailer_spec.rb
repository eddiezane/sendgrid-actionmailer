require 'mail'

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

      before { allow(SendGrid::Client).to receive(:new).and_return(client) }

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

      it 'sets a text/plain body' do
        mail.content_type = 'text/plain'
        mail.body = 'I heard you like pineapple.'
        mailer.deliver!(mail)
        expect(client.sent_mail.text).to eq('I heard you like pineapple.')
      end

      it 'sets a text/html body' do
        mail.content_type = 'text/html'
        mail.body = 'I heard you like <b>pineapple</b>.'
        mailer.deliver!(mail)
        expect(client.sent_mail.html).to eq('I heard you like <b>pineapple</b>.')
      end

      context 'multipart/alternative' do
        before do
          mail.content_type 'multipart/alternative'
          mail.part do |part|
            part.text_part = Mail::Part.new do
              content_type 'text/plain'
              body 'I heard you like pineapple.'
            end
            part.html_part = Mail::Part.new do
              content_type 'text/html'
              body 'I heard you like <b>pineapple</b>.'
            end
          end
        end

        it 'sets the text body' do
          mailer.deliver!(mail)
          expect(client.sent_mail.text).to eq('I heard you like pineapple.')
        end

        it 'sets the html body' do
          mailer.deliver!(mail)
          expect(client.sent_mail.html)
            .to eq('I heard you like <b>pineapple</b>.')
        end
      end

      context 'multipart/mixed' do
        before do
          mail.content_type 'multipart/mixed'
          mail.part do |part|
            part.text_part = Mail::Part.new do
              content_type 'text/plain'
              body 'I heard you like pineapple.'
            end
            part.html_part = Mail::Part.new do
              content_type 'text/html'
              body 'I heard you like <b>pineapple</b>.'
            end
          end
          mail.attachments['specs.rb'] = File.read(__FILE__)
        end

        it 'sets the text body' do
          mailer.deliver!(mail)
          expect(client.sent_mail.text).to eq('I heard you like pineapple.')
        end

        it 'sets the html body' do
          mailer.deliver!(mail)
          expect(client.sent_mail.html)
            .to eq('I heard you like <b>pineapple</b>.')
        end

        it 'adds the attachment' do
          mailer.deliver!(mail)
          attachment = client.sent_mail.attachments.first
          expect(attachment[:name]).to eq('specs.rb')
          expect(attachment[:file].read).to eq(File.read(__FILE__))
        end
      end
    end
  end
end
