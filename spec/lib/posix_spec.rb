describe Serial do

  before :each do
    @master, @slave = PTY.open
  end

  after :each do
    @master.close rescue nil
    @slave.close rescue nil
  end


  describe 'blocking read' do
    it 'exposes an IO object on the file descriptor' do
      expect(Serial.new(@slave.path).io).to be_kind_of(IO)
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
