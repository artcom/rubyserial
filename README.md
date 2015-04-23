# THIS IS ONLY THE FORK!

it is adding blocking read functionality. I added a config hash to the c'tor so
that you can control VMIN & VTIME termio settings for the device. VMIN was fixed
to 0 before resulting in effectively always returning immediatly from the read
call and you could not just block wait for input. But polling is bad. The other
thing i did was to add a getter for the file descriptor. This makes it possible
to use the serial device in a select call. You can also use select to avoid
polling but much more it is useful to use it to let the OS block wait on
multiple IO sources simultaneously.

It made the changes in a way which will not break existing code. Old code just
does what it did before. 

To block reading add vmin:  Serial.new(path, nil, nil, vmin: 1). This will block
until at least one character was read. 

To wait for multiple input sources use select:

  sp = Serial.new(path)
  # combine some sources in1, in2, and the serial port
  result = IO.select([in1, in2, IO.new(sp.fd)])

The IO#select call returns and array of arrays with file descriptors ready for
reading (it's more complex, see IO#select manual)


----

# rubyserial

RubySerial is a simple Ruby gem for reading from and writing to serial ports. 

Unlike other Ruby serial port implementations, it supports all of the most popular Ruby implementations (MRI, JRuby, & Rubinius) on the most popular operating systems (OSX, Linux, & Windows). And it does not require any native compilation thanks to using RubyFFI [https://github.com/ffi/ffi](https://github.com/ffi/ffi).

The interface to RubySerial should be (mostly) compatible with other Ruby serialport gems, so you should be able to drop in the new gem, change the `require` and use it as a replacement. If not, please let us know so we can address any issues.

[![Build Status](https://travis-ci.org/hybridgroup/rubyserial.svg)](https://travis-ci.org/hybridgroup/rubyserial)
[![Build status](https://ci.appveyor.com/api/projects/status/946nlaqy4443vb99/branch/master?svg=true)](https://ci.appveyor.com/project/zankich/rubyserial/branch/master)

## Installation

    $ gem install rubyserial

## Usage

```ruby
require 'rubyserial'
serialport = Serial.new '/dev/ttyACM0', 57600
```

## Methods

**write(data : String) -> Int**

Returns the number of bytes written.
Emits a `RubySerial::Exception` on error.

**read(length : Int) -> String**

Returns a string up to `length` long. It is not guaranteed to return the entire
length specified, and will return an empty string if no data is
available. Emits a `RubySerial::Exception` on error.

**getbyte -> Fixnum or nil**

Returns an 8 bit byte or nil if no data is available. 
Emits a `RubySerial::Exception` on error.

**RubySerial::Exception**

A wrapper exception type, that returns the underlying system error code.

## License

Apache 2.0. See `LICENSE` for more details.
