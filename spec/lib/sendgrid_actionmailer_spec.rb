require 'mail'
require 'webmock/rspec'

module SendGridActionMailer
  describe DeliveryMethod do
    subject(:mailer) do
      DeliveryMethod.new(api_user: 'user', api_key: 'key')
    end

    class TestClient < SendGrid::Client
      attr_reader :sent_mail

      def send(mail)
        @sent_mail = mail
        super(mail)
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

      before do
        stub_request(:any, 'https://api.sendgrid.com/api/mail.send.json')
          .to_return(body: {message: 'success'}.to_json, status: 200, headers: {'X-TEST' => 'yes'})
        allow(SendGrid::Client).to receive(:new).and_return(client)
      end

      it 'sets to' do
        mailer.deliver!(mail)
        expect(client.sent_mail.to).to eq(%w[test@sendgrid.com])
      end

      context 'there are ccs' do
        before { mail.cc = 'burrito@cat.limo' }

        it 'sets cc' do
          mailer.deliver!(mail)
          expect(client.sent_mail.cc).to eq(%w[burrito@cat.limo])
        end
      end

      context 'there are bccs' do
        before { mail.bcc = 'nachos@cat.limo' }

        it 'sets bcc' do
          mailer.deliver!(mail)
          expect(client.sent_mail.bcc).to eq(%w[nachos@cat.limo])
        end
      end

      it 'sets from' do
        mailer.deliver!(mail)
        expect(client.sent_mail.from).to eq('taco@cat.limo')
      end

      context 'from contains a friendly name' do
        before { mail.from = 'Taco Cat <taco@cat.limo>'}

        it 'sets from' do
          mailer.deliver!(mail)
          expect(client.sent_mail.from).to eq('taco@cat.limo')
        end

        it 'sets from_name' do
          mailer.deliver!(mail)
          expect(client.sent_mail.from_name).to eq('Taco Cat')
        end
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
          expect(mail.attachments.first.read).to eq(File.read(__FILE__))
          mailer.deliver!(mail)
          attachment = client.sent_mail.attachments.first
          expect(attachment[:name]).to eq('specs.rb')
        end
      end

      context 'SMTPAPI' do
        context 'it is not JSON' do
          before { mail['X-SMTPAPI'] = '<xml>JSON sucks!</xml>' }

          it 'raises a useful error' do
            expect { mailer.deliver!(mail) }.to raise_error(
              ArgumentError,
              "X-SMTPAPI is not JSON: <xml>JSON sucks!</xml>"
            )
          end
        end

        context 'filters are present' do
          before do
            mail['X-SMTPAPI'] = {
              filters: {
                clicktrack: {
                  settings: {
                    enable: 0
                  }
                },
                dkim: {
                  settings: {
                    domain: 'example.com',
                    use_from: false
                  }
                }
              }
            }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.filters).to eq({
              'clicktrack' => {
                'settings' => {
                  'enable' => 0
                }
              },
              'dkim' => {
                'settings' => {
                  'domain' => 'example.com',
                  'use_from' => false
                }
              }
            })
          end
        end

        context 'a category is present' do
          before do
            mail['X-SMTPAPI'] = { category: 'food_feline' }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.category).to eq('food_feline')
          end
        end

        context 'multiple categories are present' do
          before do
            mail['X-SMTPAPI'] = {
              category: %w[food_feline cuisine_canine]
            }.to_json
          end

          it 'attaches them all' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.category).to eq([
              'food_feline',
              'cuisine_canine',
            ])
          end
        end

        context 'send_at is present' do
          before do
            mail['X-SMTPAPI'] = {
              send_at: 1409348513
            }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.send_at).to eq(1409348513)
          end
        end

        context 'send_each_at is present' do
          before do
            mail['X-SMTPAPI'] = {
              send_each_at: [1409348513, 1409348514]
            }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.send_each_at).to eq([1409348513, 1409348514])
          end
        end

        context 'section is present' do
          before do
            mail['X-SMTPAPI'] = {
              section: {
                ":sectionName1" => "section 1 text",
                ":sectionName2" => "section 2 text"
              }
            }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.section).to eq({
              ":sectionName1" => "section 1 text",
              ":sectionName2" => "section 2 text"
            })
          end
        end

        context 'sub is present' do
          before do
            mail['X-SMTPAPI'] = {
              sub: {
                "-name-" => [
                  "John",
                  "Jane"
                ],
                "-customerID-" => [
                  "1234",
                  "5678"
                ],
              }
            }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.sub).to eq({
              "-name-" => [
                "John",
                "Jane"
              ],
              "-customerID-" => [
                "1234",
                "5678"
              ],
            })
          end
        end

        context 'asm_group_id is present' do
          before do
            mail['X-SMTPAPI'] = {
              asm_group_id: 1
            }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.asm_group_id).to eq(1)
          end
        end

        context 'unique_args are present' do
          before do
            mail['X-SMTPAPI'] = {
              unique_args: {
                customerAccountNumber: "55555",
                activationAttempt: "1",
              }
            }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.unique_args).to eq({
              "customerAccountNumber" => "55555",
              "activationAttempt" => "1",
            })
          end
        end

        context 'ip_pool is present' do
          before do
            mail['X-SMTPAPI'] = {
              ip_pool: "pool_name"
            }.to_json
          end

          it 'gets attached' do
            mailer.deliver!(mail)
            expect(client.sent_mail.smtpapi.ip_pool).to eq("pool_name")
          end
        end
      end
    end
  end
end
