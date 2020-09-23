require 'mail'
require 'webmock/rspec'

module SendGridActionMailer
  describe DeliveryMethod do
    def transform_keys(object, &block)
      SendGridActionMailer::DeliveryMethod.transform_keys(object, &block)
    end

    subject(:mailer) do
      DeliveryMethod.new(api_key: 'key')
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

    describe 'settings' do
      it 'has correct api_key' do
        m = DeliveryMethod.new(api_key: 'ABCDEFG')
        expect(m.settings[:api_key]).to eq('ABCDEFG')
      end

      it 'default raise_delivery_errors' do
        m = DeliveryMethod.new()
        expect(m.settings[:raise_delivery_errors]).to eq(false)
      end

      it 'sets raise_delivery_errors' do
        m = DeliveryMethod.new(raise_delivery_errors: true)
        expect(m.settings[:raise_delivery_errors]).to eq(true)
      end

      it 'default return_response' do
        m = DeliveryMethod.new()
        expect(mailer.settings[:return_response]).to eq(nil)
      end

      it 'sets return_response' do
        m = DeliveryMethod.new(return_response: true)
        expect(m.settings[:return_response]).to eq(true)
      end

      it 'sets perform_deliveries' do
        m = DeliveryMethod.new(perform_send_request: false)
        expect(m.settings[:perform_send_request]).to eq(false)
      end
    end

    describe '#deliver!' do
      let(:client) { TestClient.new }
      let(:client_parent) { double(client: client) }

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
        allow(SendGrid::API).to receive(:new).and_return(client_parent)
      end

      context 'with dynamic api_key' do
        let(:default) do
          Mail.new(
            to:      'test@sendgrid.com',
            from:    'taco@cat.limo',
            subject: 'Hello, world!'
          )
        end

        let(:mail) do
          Mail.new(
            to:      'test@sendgrid.com',
            from:    'taco@cat.limo',
            subject: 'Hello, world!',
            delivery_method_options: {
              api_key: 'test_key'
            }
          )
        end

        it 'sets dynamic api_key, but should revert to default settings api_key' do
          expect(SendGrid::API).to receive(:new).with(api_key: 'key')
          mailer.deliver!(default)
          expect(SendGrid::API).to receive(:new).with(api_key: 'test_key')
          mailer.deliver!(mail)
          expect(SendGrid::API).to receive(:new).with(api_key: 'key')
          mailer.deliver!(default)
        end
      end

      it 'sets to' do
        mailer.deliver!(mail)
        expect(client.sent_mail['personalizations'][0]).to include({"to"=>[{"email"=>"test@sendgrid.com"}]})
      end

      it 'returns mailer itself' do
        ret = mailer.deliver!(mail)
        expect(ret).to eq(mailer)
      end

      it 'returns api response' do
        m = DeliveryMethod.new(return_response: true, api_key: 'key')
        ret = m.deliver!(mail)
        expect(ret.status_code).to eq('200')
      end

      context 'to with a friendly name' do
        before { mail.to = 'Test SendGrid <test@sendgrid.com>' }

        it 'sets to' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to include({"to"=>[{"email"=>"test@sendgrid.com", "name"=>"Test SendGrid"}]})
        end
      end

      context 'to with a friendly name (with quotes)' do
        before { mail.to = '"Test SendGrid" <test@sendgrid.com>' }

        it 'sets to' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to include({"to"=>[{"email"=>"test@sendgrid.com", "name"=>"Test SendGrid"}]})
        end
      end

      context 'there are ccs' do
        before { mail.cc = 'burrito@cat.limo' }

        it 'sets cc' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to include({"to"=>[{"email"=>"test@sendgrid.com"}], "cc"=>[{"email"=>"burrito@cat.limo"}]})
        end
      end

      context 'there are bccs' do
        before { mail.bcc = 'nachos@cat.limo' }

        it 'sets bcc' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to include({"to"=>[{"email"=>"test@sendgrid.com"}], "bcc"=>[{"email"=>"nachos@cat.limo"}]})
        end
      end

      context 'there are bccs with a friendly name' do
        before { mail.bcc = 'Taco Cat <nachos@cat.limo>' }

        it 'sets bcc' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to include({"to"=>[{"email"=>"test@sendgrid.com"}], "bcc"=>[{"email"=>"nachos@cat.limo", "name"=>"Taco Cat"}]})
        end
      end

      context 'there are bccs with a friendly name (with quotes)' do
        before { mail.bcc = '"Taco Cat" <nachos@cat.limo>' }

        it 'sets bcc' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to include({"to"=>[{"email"=>"test@sendgrid.com"}], "bcc"=>[{"email"=>"nachos@cat.limo", "name"=>"Taco Cat"}]})
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

      context 'template_id' do
        before do
          mail['template_id'] = '1'
        end

        it 'sets a template_id' do
          mailer.deliver!(mail)
          expect(client.sent_mail['template_id']).to eq('1')
        end

        it 'does not set unsubscribe substitutions' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'].first).to_not have_key('substitutions')
        end

        it 'does not set send a content type' do
          mailer.deliver!(mail)
          expect(client.sent_mail['content']).to eq(nil)
        end

        it 'does not set send a content type even if body is given' do
          # This matches the default behavior of ActionMail. body must be
          # specified and content_type defaults to text/plain.
          mail.body = 'I heard you like pineapple.'
          mail.content_type = 'text/plain'
          mailer.deliver!(mail)
          expect(client.sent_mail['content']).to eq(nil)
        end
      end

      context 'without dynamic template data or a template id' do
        it 'sets unsubscribe substitutions' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'].first).to have_key('substitutions')
          substitutions = client.sent_mail['personalizations'].first['substitutions']
          expect(substitutions).to eq({
            '%asm_group_unsubscribe_raw_url%' => '<%asm_group_unsubscribe_raw_url%>',
            '%asm_global_unsubscribe_raw_url%' => '<%asm_global_unsubscribe_raw_url%>',
            '%asm_preferences_raw_url%' => '<%asm_preferences_raw_url%>'
          })
        end
      end

      context 'send options' do

        it 'sets sections' do
          mail['sections'] = {'%foo%' => 'bar'}
          mailer.deliver!(mail)
          expect(client.sent_mail['sections']).to eq({'%foo%' => 'bar'})
        end

        it 'sets headers' do
          mail['headers'] = {'X-FOO' => 'bar'}
          mailer.deliver!(mail)
          expect(client.sent_mail['headers']).to eq({'X-FOO' => 'bar'})
        end

        it 'sets categories' do
          mail['categories'] = ['foo', 'bar']
          mailer.deliver!(mail)
          expect(client.sent_mail['categories']).to eq(['foo', 'bar'])
        end

        it 'sets custom_args' do
          mail['custom_args'] =  {'campaign' => 'welcome'}
          mailer.deliver!(mail)
          expect(client.sent_mail['custom_args']).to eq({'campaign' => 'welcome'})
        end

        it 'sets send_at and batch_id' do
          epoch = Time.now.to_i
          mail['send_at'] = epoch
          mail['batch_id'] = 3
          mailer.deliver!(mail)
          expect(client.sent_mail['send_at']).to eq(epoch)
          expect(client.sent_mail['batch_id']).to eq('3')
        end

        it 'sets asm' do
          asm = {group_id: 99, groups_to_display: [4,5,6,7,8]}
          mail['asm'] = asm
          mailer.deliver!(mail)
          expect(client.sent_mail['asm']).to eq(transform_keys(asm, &:to_s))
        end

        it 'sets ip_pool_name' do
          mail['ip_pool_name'] = 'marketing'
          mailer.deliver!(mail)
          expect(client.sent_mail['ip_pool_name']).to eq('marketing')
        end

        it 'should not change values inside custom args' do
          custom_args = { 'text' => 'line with a => in it' }
          mail['custom_args'] = custom_args
          mailer.deliver!(mail)
          expect(client.sent_mail['custom_args']).to eq('text' => 'line with a => in it')
        end

        context 'mail_settings' do
          it 'sets bcc' do
            bcc = { bcc: { enable: true, email: 'test@example.com' }}
            mail['mail_settings'] = bcc
            mailer.deliver!(mail)
            expect(client.sent_mail['mail_settings']).to eq(transform_keys(bcc, &:to_s))
          end

          it 'sets bypass_list_management' do
            bypass = { bypass_list_management: { enable: true }}
            mail['mail_settings'] = bypass
            mailer.deliver!(mail)
            expect(client.sent_mail['mail_settings']).to eq(transform_keys(bypass, &:to_s))
          end

          it 'sets footer' do
            footer = {footer: { enable: true, text: 'Footer Text', html: '<html><body>Footer Text</body></html>'}}
            mail['mail_settings'] = footer
            mailer.deliver!(mail)
            expect(client.sent_mail['mail_settings']).to eq(transform_keys(footer, &:to_s))
          end

          it 'sets sandbox_mode' do
            sandbox = {sandbox_mode: { enable: true }}
            mail['mail_settings'] = sandbox
            mailer.deliver!(mail)
            expect(client.sent_mail['mail_settings']).to eq(transform_keys(sandbox, &:to_s))
          end

          it 'sets spam_check' do
            spam_check = {spam_check: { enable: true, threshold: 1, post_to_url: 'https://spamcatcher.sendgrid.com'}}
            mail['mail_settings'] = spam_check
            mailer.deliver!(mail)
            expect(client.sent_mail['mail_settings']).to eq(transform_keys(spam_check, &:to_s))
          end
        end

        context 'tracking_settings' do
          it 'sets click_tracking' do
            tracking = { click_tracking: { enable: false, enable_text: false }}
            mail['tracking_settings'] = tracking.dup
            mailer.deliver!(mail)
            expect(client.sent_mail['tracking_settings']).to eq(transform_keys(tracking, &:to_s))
          end

          it 'sets open_tracking' do
            tracking = { open_tracking: { enable: true, substitution_tag: 'Optional tag to replace with the open image in the body of the message' }}
            mail['tracking_settings'] = tracking
            mailer.deliver!(mail)
            expect(client.sent_mail['tracking_settings']).to eq(transform_keys(tracking, &:to_s))
          end

          it 'sets subscription_tracking' do
            tracking = { subscription_tracking: { enable: true, text: 'text to insert into the text/plain portion of the message', html: 'html to insert into the text/html portion of the message', substitution_tag: 'Optional tag to replace with the open image in the body of the def message' }}
            mail['tracking_settings'] = tracking
            mailer.deliver!(mail)
            expect(client.sent_mail['tracking_settings']).to eq(transform_keys(tracking, &:to_s))
          end

          it 'sets ganalytics' do
            tracking = { ganalytics: { enable: true, utm_source: 'some source', utm_medium: 'some medium', utm_term: 'some term', utm_content: 'some content', utm_campaign: 'some campaign' }}
            mail['tracking_settings'] = tracking
            mailer.deliver!(mail)
            expect(client.sent_mail['tracking_settings']).to eq(transform_keys(tracking, &:to_s))
          end
        end

        context 'dynamic template data' do
          let(:template_data) do
            { variable_1: '1', variable_2: '2' }
          end
          
          before { mail['dynamic_template_data'] = template_data }

          it 'sets dynamic_template_data' do
            mailer.deliver!(mail)
            expect(client.sent_mail['personalizations'].first['dynamic_template_data']).to eq(template_data)
          end

          it 'does not set unsubscribe substitutions' do
            mailer.deliver!(mail)
            expect(client.sent_mail['personalizations'].first).to_not have_key('substitutions')
          end

          context 'containing what looks like hash syntax' do
            let(:template_data) do
              { hint: 'Just use => instead of :' }
            end

            it 'does not change values inside dynamic template data' do
              mailer.deliver!(mail)
              expect(
                client.sent_mail['personalizations'].first['dynamic_template_data']
              ).to eq(template_data)
            end
          end
        end

        it 'sets dynamic template data and sandbox_mode' do
          mail['mail_settings'] = {}
          mailer.deliver!(mail)
          expect(client.sent_mail['mail_settings']).to eq(nil)
        end
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
          expect(mail.attachments.first.read).to include("it 'adds the attachment' do")
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
          expect(mail.attachments.first.read).to include("it 'adds the inline attachment' do")
          mailer.deliver!(mail)
          content = client.sent_mail['attachments'].first
          expect(content['filename']).to eq('specs.rb')
          expect(content['type']).to eq('application/x-ruby')
          expect(content['content_id'].class).to eq(String)
          expect(content['content_id']).to include("@")
          expect(content['content_id']).not_to include("<")
          expect(content['content_id']).not_to include(">")
        end
      end

      context 'with personalizations' do
        let(:personalizations) do
          [
            {
              'to' => [
                {'email' => 'john1@example.com', 'name' => 'John 1'},
                {'email' => 'john2@example.com', 'name' =>  'John 2'},
              ]
            },
            {
              'to' => [
                {'email' => 'john3@example.com', 'name' => 'John 3'},
                {'email' => 'john4@example.com'}
              ],
              'cc' => [
                {'email' => 'cc@example.com'}
              ],
              'bcc' => [
                {'email' => 'bcc@example.com'}
              ],
              'substitutions' => {
                '%fname%' => 'Bob'
              },
              'subject' => 'personalized subject',
              'send_at' => 1443636843,
              'custom_args' => {
                'user_id' => '343'
              },
              'headers' => {
                'X-Test' => true
              }
            }
          ]
        end

        before do
          mail.to = nil
          mail.cc = nil
          mail.bcc = nil
          mail['personalizations'] = personalizations
        end

        it 'sets the provided to address personalizations' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'].length).to eq(2)
          expect(client.sent_mail['personalizations'][0]['to']).to eq(personalizations[0]['to'])
          expect(client.sent_mail['personalizations'][1]['to']).to eq(personalizations[1]['to'])
        end

        it 'sets the provided cc address personalizations' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to_not have_key('cc')
          expect(client.sent_mail['personalizations'][1]['cc']).to eq(personalizations[1]['cc'])
        end

        it 'sets the provided bcc address personalizations' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to_not have_key('bcc')
          expect(client.sent_mail['personalizations'][1]['bcc']).to eq(personalizations[1]['bcc'])
        end

        it 'sets the provided subject personalizations' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to_not have_key('subject')
          expect(client.sent_mail['personalizations'][1]['subject']).to eq(personalizations[1]['subject'])
        end

        it 'sets the provided headers personalizations' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to_not have_key('headers')
          expect(client.sent_mail['personalizations'][1]['headers']).to eq(personalizations[1]['headers'])
        end

        it 'sets the provided custom_arg personalizations' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to_not have_key('custom_args')
          expect(client.sent_mail['personalizations'][1]['custom_args']).to eq(personalizations[1]['custom_args'])
        end

        it 'sets the provided send_at personalizations' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]).to_not have_key('send_at')
          expect(client.sent_mail['personalizations'][1]['send_at']).to eq(personalizations[1]['send_at'])
        end

        it 'sets the provided substitution personalizations' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][1]['substitutions']).to include(personalizations[1]['substitutions'])
        end

        it 'adds to the unsubscribe link substitutions' do
          mailer.deliver!(mail)
          expect(client.sent_mail['personalizations'][0]['substitutions']).to eq({
            '%asm_group_unsubscribe_raw_url%' => '<%asm_group_unsubscribe_raw_url%>',
            '%asm_global_unsubscribe_raw_url%' => '<%asm_global_unsubscribe_raw_url%>',
            '%asm_preferences_raw_url%' => '<%asm_preferences_raw_url%>'
          })
          expect(client.sent_mail['personalizations'][1]['substitutions']).to include({
            '%asm_group_unsubscribe_raw_url%' => '<%asm_group_unsubscribe_raw_url%>',
            '%asm_global_unsubscribe_raw_url%' => '<%asm_global_unsubscribe_raw_url%>',
            '%asm_preferences_raw_url%' => '<%asm_preferences_raw_url%>'
          })
        end

        context 'with symbols used as keys' do
        let(:personalizations) do
          [
            {
              to: [
                {email: 'sally1@example.com', name: 'Sally 1'},
                {email: 'sally2@example.com', name: 'Sally 2'},
              ]
            }
          ]
          end

          it 'still works' do
            mailer.deliver!(mail)
            expect(client.sent_mail['personalizations'].length).to eq(1)
            expected_to = personalizations[0][:to].map { |t| transform_keys(t, &:to_s) }
            expect(client.sent_mail['personalizations'][0]['to']).to eq(expected_to)
          end
        end

        context 'dynamic template data passed into a personalizaiton' do
          let(:personalization_data) do
            {
              'variable_1' => '1', 'variable_2' => '2'
            }
          end

          let(:personalizations_with_dynamic_data) do
            personalizations.tap do |p|
              p[1]['dynamic_template_data'] = personalization_data
            end
          end

          before do
            mail['personalizations'] = nil
            mail['personalizations'] = personalizations_with_dynamic_data
          end

          it 'sets the provided dynamic template data personalizations' do
            mailer.deliver!(mail)
            expect(client.sent_mail['personalizations'][0]).to_not have_key('dynamic_template_data')
            expect(client.sent_mail['personalizations'][1]['dynamic_template_data']).to eq(personalization_data)
          end

          context 'dynamic template data is also set on the mail object' do
            let(:mail_template_data) do
              { 'variable_3' => '1', 'variable_4' => '2' }
            end

            before { mail['dynamic_template_data'] = mail_template_data.dup }

            it 'sets dynamic_template_data where not also provided as a personalization' do
              mailer.deliver!(mail)
              expect(client.sent_mail['personalizations'][0]['dynamic_template_data']).to eq(mail_template_data)
            end

            it 'merges the template data with a personalizations dynamic data' do
              mailer.deliver!(mail)
              expect(client.sent_mail['personalizations'][1]['dynamic_template_data']).to eq(
                mail_template_data.merge(personalization_data)
              )
            end
          end
        end

        context 'when to is set on mail object' do
          before { mail.to = 'test@sendgrid.com' }

          it 'adds that to address as a separate personalization' do
            mailer.deliver!(mail)
            expect(client.sent_mail['personalizations'].length).to eq(3)
            expect(client.sent_mail['personalizations'][0]['to']).to eq(personalizations[0]['to'])
            expect(client.sent_mail['personalizations'][1]['to']).to eq(personalizations[1]['to'])
            expect(client.sent_mail['personalizations'][2]['to']).to eq([{"email"=>"test@sendgrid.com"}])
          end
        end

        context 'when cc is set on mail object' do
          before { mail.cc = 'test@sendgrid.com' }

          it 'adds that cc address as a separate personalization' do
            mailer.deliver!(mail)
            expect(client.sent_mail['personalizations'].length).to eq(3)
            expect(client.sent_mail['personalizations'][0]['cc']).to eq(personalizations[0]['cc'])
            expect(client.sent_mail['personalizations'][1]['cc']).to eq(personalizations[1]['cc'])
            expect(client.sent_mail['personalizations'][2]['cc']).to eq([{"email"=>"test@sendgrid.com"}])
          end
        end

        context 'when bcc is set on mail object' do
          before { mail.bcc = 'test@sendgrid.com' }

          it 'adds that bcc address as a separate personalization' do
            mailer.deliver!(mail)
            expect(client.sent_mail['personalizations'].length).to eq(3)
            expect(client.sent_mail['personalizations'][0]['bcc']).to eq(personalizations[0]['bcc'])
            expect(client.sent_mail['personalizations'][1]['bcc']).to eq(personalizations[1]['bcc'])
            expect(client.sent_mail['personalizations'][2]['bcc']).to eq([{"email"=>"test@sendgrid.com"}])
          end
        end

        context 'when perform_send_request false' do
          it 'should not send and email and return json body' do
            m = DeliveryMethod.new(perform_send_request: false, return_response: true, api_key: 'key')
            response = m.deliver!(mail)
            expect(response).to respond_to(:to_json)
          end
        end

        context 'when mail_settings are present' do
          it 'should apply mail_settings to request body' do
            m = DeliveryMethod.new(api_key: 'key', return_response: true,  mail_settings: { sandbox_mode: {enable: true }})
            m.deliver!(mail)
            expect(client.sent_mail['mail_settings']).to eq({ sandbox_mode: {enable: true }}.to_json)
          end
        end
      end
    end
  end
end
