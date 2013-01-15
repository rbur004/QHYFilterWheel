#!/usr/bin/ruby
require 'rubygems'
require 'serialport'
require 'readbytes'

class SerialBlocking
  PORT = '/dev/cu.USA28Xfa43P1.1'
  BAUD = 9600
  BITS = 8
  STOPBITS = 1
  PARITY = SerialPort::NONE

  def initialize(port = PORT, speed = BAUD, bits = BITS, stopbits = STOPBITS, parity = PARITY)
    open_serial_port(port, speed, bits, stopbits, parity)
  end
  
  def offline?
    @sp == nil
  end
  
  def connect(port = PORT, speed = BAUD, bits = BITS, stopbits = STOPBITS, parity = PARITY)
    puts "failed to connect"
    #open_serial_port(port, speed, bits, stopbits, parity) if offline?
  end
  
  def exchange(send_bytes, response_nbytes )
    write(send_bytes)
    readbytes(response_nbytes)
  end
  
  def readbytes(nbytes = 1)
    if @sp != nil
      begin
        @sp.readbytes(nbytes)
      rescue
        ''
      end
    else
      '' 
    end
  end
  
  def write(bytes)
    if @sp != nil
      begin
        @sp.write(bytes)
      rescue
        ''
      end
    else
      ''
    end
  end
  
  def close
    @sp.close if @sp != nil
    @sp = nil
  end
  
  def self.open(port = PORT, speed = BAUD, bits = BITS, stopbits = STOPBITS, parity = PARITY)
    begin
      open_serial_port(port, speed, bits, stopbits, parity)
        yield @sp
      @sp.close
    rescue => error
      puts error
      @sp = nil
    end
  end
  
  private 
  def open_serial_port(port = PORT, speed = BAUD, bits = BITS, stopbits = STOPBITS, parity = PARITY)
    begin
      @sp = SerialPort.new(port, speed, bits, stopbits, parity)
      @sp.flow_control = SerialPort::NONE
      @sp.read_timeout = 0
    rescue => error
      puts error
      @sp = nil
    end
  end

end

class FilterWheel < SerialBlocking

  #The RS232 is set to 9600bps
  def self.open(device = '/dev/cu.USA28Xfa43P1.1')
    @s = self.new '/dev/cu.USA28Xfa43P1.1' , 9600
    begin
      yield @s
    ensure
      @s.close
    end
  end
  
  #The motor only rotate toward one direction to avoid the back space of the gear.   
  #For example:
  #         The current posiiton is 2,  to goto 4   the motor will rotate to 4
  #         The current position is 2 , to goto 1   the motor will rotate to 3,4,0 then to 1
  #And in every time it reaches position 0, the colorwheel will do a calibration.

  #The calibration use a linear magic sensor. The ADC in colorwheel will read the magic 
  #intensity and find out the maxium intensity. This gives an accurate initial position.
  #Control byte  "0"                goto position 0 #Blue
  #Control byte  "1"                goto position 1
  #Control byte  "2"                goto position 2
  #Control byte  "3"                goto position 3
  #Control byte  "4"                goto position 4
  #Wheel returns a '-' character when it gets to the position.
  def position(n = 0)
      exchange n.to_s, 1
  end
  
  #The default position of the 5 color wheel is
  #positon    0------------------------- 85
  #           1-------------------------189
  #           2-------------------------293
  #           3-------------------------394
  #           4-------------------------498
  #           5-------------------------600
  #           6-------------------------700
  #           7-------------------------800
  def reset_factory_defaults
    write "SEF"
  end
  
  def get_wheel_positions
    x = exchange( "SEG", 17 )
    x.unpack('Cnnnnnnnn') 
  end
  
  #setting the colorwheel position
  #Byte 0:  Colorwheel type   00: 5 position
  #Byte 1 to Byte 16    :   8 word. Each word is one position in network byte order
  #Works, but I have to power cycle the wheel afterward?
  def set_wheel_positions(type = 0, positions = [85,189,293,394,498,600,700,800])
    write "SEW" + [type].pack('C') + positions.pack('nnnnnnnn')
  end


end

#1 Clear filter
#3 Ha
#
#0 
FilterWheel.open do |fw|
  #fw.set_wheel_positions(0, [89,189,293,391,490,600,700,800])
  #fw.get_wheel_positions.each { |i| puts i } 
  puts fw.position(0) 
end
