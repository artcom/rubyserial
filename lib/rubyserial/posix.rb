require 'ffi'

class Serial

  Defaults = {
    baude_rate: 9600, 
    data_bits: 8,
    vmin: 0,
  }

  attr_reader :config

  # config value order is, in that order, from low to high: 
  # 
  #   config hash  -over-> baud_rate, data_bits -over->  Defaults
  #
  def initialize(address, baude_rate = nil, data_bits = nil, config = {})
    # XXX this is kind of ugly, but neccessary to preserve old orginal code
    # behaviour with default values
    config[:baude_rate] ||= (baude_rate || Defaults[:baude_rate])
    config[:data_bits] ||= (data_bits || Defaults[:data_bits])
    @config = Defaults.merge(config)

    file_opts = RubySerial::Posix::O_RDWR | RubySerial::Posix::O_NOCTTY | RubySerial::Posix::O_NONBLOCK
    @fd = RubySerial::Posix.open(address, file_opts)

    if @fd == -1
      raise RubySerial::Exception, RubySerial::Posix::ERROR_CODES[FFI.errno]
    else
      @open = true
    end

    fl = RubySerial::Posix.fcntl(@fd, RubySerial::Posix::F_GETFL, :int, 0)
    if fl == -1
      raise RubySerial::Exception, RubySerial::Posix::ERROR_CODES[FFI.errno]
    end

    err = RubySerial::Posix.fcntl(@fd, RubySerial::Posix::F_SETFL, :int, ~RubySerial::Posix::O_NONBLOCK & fl)
    if err == -1
      raise RubySerial::Exception, RubySerial::Posix::ERROR_CODES[FFI.errno]
    end

    termio = build_config(@config)
    err = RubySerial::Posix.tcsetattr(@fd, RubySerial::Posix::TCSANOW, termio)
    if err == -1
      raise RubySerial::Exception, RubySerial::Posix::ERROR_CODES[FFI.errno]
    end
  end

  def closed?
    !@open
  end

  # use the file descriptor, or IO object instance around it, for blocking read
  # with IO#select or for waiting on multiple i/o lines & events
  #
  attr_reader :fd
  def io; @io ||= IO.new(@fd); end

  def close
    err = RubySerial::Posix.close(@fd)
    if err == -1
      raise RubySerial::Exception, RubySerial::Posix::ERROR_CODES[FFI.errno]
    else
      @open = false
    end
  end

  def write(data)
    data = data.to_s
    n =  0
    while data.size > n do
      buff = FFI::MemoryPointer.from_string(data[n..-1].to_s)
      i = RubySerial::Posix.write(@fd, buff, buff.size-1)
      if i == -1
        raise RubySerial::Exception, RubySerial::Posix::ERROR_CODES[FFI.errno]
      else
        n = n+i
      end
    end

    # return number of bytes written
    n
  end

  def read(size)
    buff = FFI::MemoryPointer.new :char, size
    i = RubySerial::Posix.read(@fd, buff, size)
    if i == -1
      raise RubySerial::Exception, RubySerial::Posix::ERROR_CODES[FFI.errno]
    end
    buff.get_bytes(0, i)
  end

  def getbyte
    buff = FFI::MemoryPointer.new :char, 1
    i = RubySerial::Posix.read(@fd, buff, 1)
    if i == -1
      raise RubySerial::Exception, RubySerial::Posix::ERROR_CODES[FFI.errno]
    end

    if i == 0
      nil
    else
      buff.get_bytes(0,1).bytes.first
    end
  end

  def gets(sep=$/, limit=nil)
    sep = "\n\n" if sep == ''
    # This allows the method signature to be (sep) or (limit)
    (limit = sep; sep="\n") if sep.is_a? Integer
    bytes = []
    loop do
      current_byte = getbyte
      bytes << current_byte unless current_byte.nil?
      break if (bytes.last(sep.bytes.to_a.size) == sep.bytes.to_a) || ((bytes.size == limit) if limit)
    end

    bytes.map { |e| e.chr }.join
  end

  private

  def build_config(opts)
    termio = RubySerial::Posix::Termios.new

    termio[:c_iflag]  = RubySerial::Posix::IGNPAR
    termio[:c_ispeed] = RubySerial::Posix::BAUDE_RATES[opts[:baude_rate]]
    termio[:c_ospeed] = RubySerial::Posix::BAUDE_RATES[opts[:baude_rate]]
    termio[:c_cflag]  = RubySerial::Posix::DATA_BITS[opts[:data_bits]] |
      RubySerial::Posix::CREAD |
      RubySerial::Posix::CLOCAL |
      RubySerial::Posix::BAUDE_RATES[opts[:baude_rate]]

    termio[:cc_c][RubySerial::Posix::VMIN] = opts[:vmin]

    termio
  end
end
