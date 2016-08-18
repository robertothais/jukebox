module Machine

  PORTS = {
    'osx'    => [ '/dev/tty.usbmodem*' ],
    'linux'  => [ '/dev/ttyACM*' ]
  }

  @@info = `uname -as`

  def self.hardware
    pi? ? 'pi' : 'workstation'
  end

  def self.os
    if linux?
      'linux'
    elsif osx?
      'osx'
    end
  end

  def self.pi?
    @@info.include?('arm')
  end

  def self.workstation?
    !pi?
  end

  def self.linux?
    @@info.include?('Linux')
  end

  def self.osx?
    @@info.include?('Darwin')
  end

  def self.ports
    PORTS[os]
  end

  def self.connected_ports
    `ls #{ports.join(" ")}`.split("\n")
  end

end