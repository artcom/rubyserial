describe Serial do

  before :each do
    @master, @slave = PTY.open
  end

  after :each do
    #@slave.read_nonblock(255) rescue nil
    @master.close rescue nil
    @slave.close rescue nil
  end

  describe 'new config option settings' do
    it 'has a queryable config attribute' do
      expect(Serial.new(@slave.path).config).to be_kind_of(Hash)
    end
    it 'has a default baud rate' do
      expect(Serial.new(@slave.path).config[:baude_rate]).to eq(9600)
    end
    it 'overwrites default baude rate' do
      expect(Serial.new(@slave.path, 57600).config[:baude_rate]).to eq(57600)
    end
    it 'overwrites default baude rate with config' do
      expect(
        Serial.new(@slave.path, nil, nil, baude_rate: 57600
      ).config[:baude_rate]).to eq(57600)
    end

    it 'has default data bits' do
      expect(Serial.new(@slave.path).config[:data_bits]).to eq(8)
    end
    it 'overwrites default data bits' do
      expect(Serial.new(@slave.path, nil, 7).config[:data_bits]).to eq(7)
    end
    it 'overwrites default data bits with config' do
      expect(
        Serial.new(@slave.path, nil, nil, data_bits: 7
      ).config[:data_bits]).to eq(7)
    end

    it 'defaults to VMIN = 0' do
      expect(Serial.new(@slave.path).config[:vmin]).to eq(0)
    end
    it 'allows overwriting VMIN' do
      expect(
        Serial.new(@slave.path, nil, nil, vmin: 1
      ).config[:vmin]).to eq(1)
    end
  end

  describe 'blocking read with VMIN=1' do
    let(:sp) { Serial.new(@slave.path, nil, nil, vmin: 1) }
    it 'blocks on read' do 
      s = ''
      c = :start
      t = Thread.new { 
        s = sp.read(255)
        expect(s).to eq('hello')
        c = :end
      }
      expect(c).to eq(:start)
      expect(s).to eq('')
      @master.write('hello')
      t.join
      expect(c).to eq(:end)
    end
  
    it 'does not block with default VMIN=0' do
      c = :start
      Thread.new { 
        s = sp.read(255)
        expect(s).to eq('')
        c = :end
      }.join
      expect(c).to eq(:end)
    end
  end

  describe 'synchronous operation (ported from rubyserial_spec.rb)' do

    let(:sp) { Serial.new @slave.path }

    it "writes" do
      sp.write('hello')
      expect(@master.read_nonblock(0xff)).to eql('hello')
    end
    it "reads" do
      @master.write('hello')
      expect(sp.read(0xff)).to eql('hello')
    end

    it "converts ints to strings" do
      expect(sp.write(123)).to eql(3)
      expect(@master.read_nonblock(3)).to eql('123')
    end

    it "returns the numbers of bytes written" do
      expect(sp.write('hello')).to eql(5)
    end

    it "reading nothing should be blank" do
      expect(sp.read(5)).to eql('')
    end

    it "should give me nil on getbyte" do
      expect(sp.getbyte).to be_nil
    end

    it 'should give me a zero byte from getbyte' do
      @master.write("\x00")
      expect(sp.getbyte).to eql(0)
    end

    it "should give me bytes" do
      @master.write('hello')
      expect([sp.getbyte].pack('C')).to eql('h')
    end

    describe "giving me lines" do
      it "should give me a line" do
        @master.write("no yes \n hello")
        expect(sp.gets).to eql("no yes \n")
      end

      it "should accept a sep param" do
        @master.write('no yes END bleh')
        expect(sp.gets('END')).to eql("no yes END")
      end

      it "should accept a limit param" do
        @master.write("no yes \n hello")
        expect(sp.gets(4)).to eql("no y")
      end

      it "should accept limit and sep params" do
        @master.write("no yes END hello")
        expect(sp.gets('END', 20)).to eql("no yes END")
        sp.read(1000) # to clear the device?
        @master.write("no yes END hello")
        expect(sp.gets('END', 4)).to eql('no y')
      end

      it "should read a paragraph at a time" do
        @master.write("Something \n Something else \n\n and other stuff")
        expect(sp.gets('')).to eql("Something \n Something else \n\n")
      end
    end

  end # ~synchronous operation 
end
