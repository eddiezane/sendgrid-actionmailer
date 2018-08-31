require 'mail'
require 'webmock/rspec'

module SendGridActionMailer
  describe DeliveryMethod do
    subject(:mailer) do
      DeliveryMethod.new(api_user: 'user', api_key: 'key')
    end

    class TestClient
      attr_reader :sent_mail

      def send(mail)
        @sent_mail = mail
        super(mail)
      end

      def mail()
        self
      end

      def _(param)
        return self if param == 'send'
        raise "Unknown param #{param.inspect}"
      end

      def post(request_body:)
        @sent_mail = request_body
        OpenStruct.new(status_code: '200')
      end
    end

    describe '#deliver!' do
      let(:client) { TestClient.new }
      let(:mail) do
        Mail.new(
          to:      'test@sendgrid.com',
          from:    'taco@cat.limo',
          subject: 'Hello, world!',
        )
      end

      before do
        stub_request(:any, 'https://api.sendgrid.com/api/mail.send.json')
          .to_return(body: {message: 'success'}.to_json, status: 200, headers: {'X-TEST' => 'yes'})
        allow(SendGrid::Client).to receive(:new).and_return(client)
      end

      it 'sets to' do
        mailer.deliver!(mail)
        expect(client.sent_mail['personalizations'][0]).to eq({"to"=>[{"email"=>"test@sendgrid.com"}]})
      end

      context 'to with a friendly name' do
        before { mail.to = 'Test SendGrid <test@sendgrid.com>' }

        it 'sets to' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to eq({"to"=>[{"email"=>"test@sendgrid.com", "name"=>"Test SendGrid"}]})
        end
      end

      context 'to with a friendly name (with quotes)' do
        before { mail.to = '"Test SendGrid" <test@sendgrid.com>' }

        it 'sets to' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to eq({"to"=>[{"email"=>"test@sendgrid.com", "name"=>"Test SendGrid"}]})
        end
      end

      context 'there are ccs' do
        before { mail.cc = 'burrito@cat.limo' }

        it 'sets cc' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to eq({"to"=>[{"email"=>"test@sendgrid.com"}], "cc"=>[{"email"=>"burrito@cat.limo"}]})
        end
      end

      context 'there are bccs' do
        before { mail.bcc = 'nachos@cat.limo' }

        it 'sets bcc' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to eq({"to"=>[{"email"=>"test@sendgrid.com"}], "bcc"=>[{"email"=>"nachos@cat.limo"}]})
        end
      end

      context 'there are bccs with a friendly name' do
        before { mail.bcc = 'Taco Cat <nachos@cat.limo>' }

        it 'sets bcc' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to eq({"to"=>[{"email"=>"test@sendgrid.com"}], "bcc"=>[{"email"=>"nachos@cat.limo", "name"=>"Taco Cat"}]})
        end
      end

      context 'there are bccs with a friendly name (with quotes)' do
        before { mail.bcc = '"Taco Cat" <nachos@cat.limo>' }

        it 'sets bcc' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to eq({"to"=>[{"email"=>"test@sendgrid.com"}], "bcc"=>[{"email"=>"nachos@cat.limo", "name"=>"Taco Cat"}]})
        end
      end

      context 'there is a reply to' do
        before { mail.reply_to = 'nachos@cat.limo' }

        it 'sets reply_to' do
          mailer.deliver!(mail)
          expect(client.sent_mail['reply_to']).to eq({'email' => 'nachos@cat.limo'})
        end
      end

      context 'there is a reply to with a friendly name' do
        before { mail.reply_to = 'Taco Cat <nachos@cat.limo>' }

        it 'sets reply_to' do
          mailer.deliver!(mail)
          expect(client.sent_mail['reply_to']).to eq('email' => 'nachos@cat.limo', 'name' => 'Taco Cat')
        end
      end

      context 'from contains a friendly name' do
        before { mail.from = 'Taco Cat <taco@cat.limo>'}

        it 'sets from' do
          mailer.deliver!(mail)
          expect(client.sent_mail['from']).to eq('email' => 'taco@cat.limo', 'name' => 'Taco Cat')
        end
      end

      context 'from contains a friendly name (with quotes)' do
        before { mail.from = '"Taco Cat" <taco@cat.limo>'}

        it 'sets from' do
          mailer.deliver!(mail)
          expect(client.sent_mail['from']).to eq('email' => 'taco@cat.limo', 'name' => 'Taco Cat')
        end
      end

      it 'sets subject' do
        mailer.deliver!(mail)
        expect(client.sent_mail['subject']).to eq('Hello, world!')
      end

      it 'sets a text/plain body' do
        mail.content_type = 'text/plain'
        mail.body = 'I heard you like pineapple.'
        mailer.deliver!(mail)
        expect(client.sent_mail['content']).to eq([
          {
            'type' => 'text/plain',
            'value' => 'I heard you like pineapple.'
          }
        ])
      end

      it 'sets a text/html body' do
        mail.content_type = 'text/html'
        mail.body = 'I heard you like <b>pineapple</b>.'
        mailer.deliver!(mail)

        expect(client.sent_mail['content']).to eq([
          {
            'type' => 'text/html',
            'value' => 'I heard you like <b>pineapple</b>.'
          }
        ])
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

        it 'sets the text and html body' do
          mailer.deliver!(mail)
          expect(client.sent_mail['content']).to include({
            'type' => 'text/html',
            'value' => 'I heard you like <b>pineapple</b>.'
          })
          expect(client.sent_mail['content']).to include({
            'type' => 'text/plain',
            'value' => 'I heard you like pineapple.'
          })
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

        it 'sets the text and html body' do
          mailer.deliver!(mail)
          expect(client.sent_mail['content']).to include({
            'type' => 'text/html',
            'value' => 'I heard you like <b>pineapple</b>.'
          })
          expect(client.sent_mail['content']).to include({
            'type' => 'text/plain',
            'value' => 'I heard you like pineapple.'
          })
        end

        it 'adds the attachment' do
          expect(mail.attachments.first.read).to eq(File.read(__FILE__))
          mailer.deliver!(mail)
          attachment = client.sent_mail['attachments'].first
          expect(attachment['filename']).to eq('specs.rb')
          expect(attachment['type']).to eq('application/x-ruby')
        end
      end

      context 'multipart/related' do
        before do
          mail.content_type 'multipart/related'
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
          mail.attachments.inline['specs.rb'] = File.read(__FILE__)
        end

        it 'sets the text and html body' do
          mailer.deliver!(mail)
          expect(client.sent_mail['content']).to include({
            'type' => 'text/html',
            'value' => 'I heard you like <b>pineapple</b>.'
          })
          expect(client.sent_mail['content']).to include({
            'type' => 'text/plain',
            'value' => 'I heard you like pineapple.'
          })
        end

        it 'adds the inline attachment' do
          expect(mail.attachments.first.read).to eq(File.read(__FILE__))
          mailer.deliver!(mail)
          content = client.sent_mail['attachments'].first
          expect(content['filename']).to eq('specs.rb')
          expect(content['type']).to eq('application/x-ruby')
          expect(content['content_id'].class).to eq(String)
        end
      end
    end
  end
end
