describe SendGridActionMailer::SmtpapiSetter do
  describe '#set!' do
    subject { SendGridActionMailer::SmtpapiSetter.new(email, mail) }

    let(:email) { SendGrid::Mail.new }
    let(:mail) { Mail.new.tap { |m| m['X-SMTPAPI'] = smtpapi } }

    context 'when it is not JSON' do
      let(:smtpapi) { '<xml>JSON sucks!</xml>' }

      it 'raises a useful error' do
        expect { subject.set! }.to raise_error(
          ArgumentError,
          "X-SMTPAPI is not JSON: <xml>JSON sucks!</xml>"
        )
      end
    end

    context 'a category is present' do
      let(:smtpapi) { { category: 'food_feline' }.to_json }

      it 'gets attached' do
        subject.set!
        expect(email.smtpapi.category).to include('food_feline')
      end
    end

    context 'multiple categories are present' do
      let(:smtpapi) { { category: %w[food_feline cuisine_canine] }.to_json }

      it 'attaches them all' do
        subject.set!
        expect(email.smtpapi.category)
          .to include('food_feline', 'cuisine_canine')
      end
    end

    context 'a unique_arg is present' do
      let(:smtpapi) { { unique_args: { foo: 'bar' } }.to_json }

      it 'adds it' do
        subject.set!
        expect(email.smtpapi.unique_args).to have_key('foo')
        expect(email.smtpapi.unique_args['foo']).to eq('bar')
      end
    end

    context 'two unique_args are present' do
      let(:smtpapi) { { unique_args: { foo: 'bar', baz: 'bing' } }.to_json }

      it 'adds both' do
        subject.set!
        expect(email.smtpapi.unique_args).to have_key('foo')
        expect(email.smtpapi.unique_args['foo']).to eq('bar')
        expect(email.smtpapi.unique_args).to have_key('baz')
        expect(email.smtpapi.unique_args['baz']).to eq('bing')
      end
    end
  end
end
