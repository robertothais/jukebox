require './environment'
require 'uri'

module Commands
  def ssh_command
    "ssh #{ENV['PI_USER']}@#{ENV['PI_HOSTNAME']}"
  end

  def copy_command(origin, destination)
    "sudo cp #{origin} #{destination}"
  end

  def remotely(*args)
    "#{ssh_command} '#{args.join(';')}'"
  end

  def console_command
    'bundle exec irb -r ./environment.rb'
  end

  def restart_command
    'sudo restart jukebox'
  end

  def upload_command
    "rsync -avzhe ssh --delete-after --exclude '.git' --exclude 'vendor/bundle' --exclude '.bundle' . #{ENV['PI_USER']}@#{ENV['PI_HOSTNAME']}:/home/pi/jukebox"
  end
end

class Pi < Thor
  include Commands
  include Thor::Actions

  HOSTNAME='raspberrypi.local'
  USER='pi'

  desc 'ssh', 'SSH into the raspberry pi'
  def ssh
    run ssh_command
  end

  desc 'reboot', 'Reboots the raspberry pi'
  def reboot
    run remotely("sudo reboot")
  end

  desc 'upload', 'Uploads project files into raspberry pi'
  def upload
    run upload_command
  end

  desc 'deploy', 'Deploys the project into raspberry pi'
  def deploy
    run 'bundle package'
    run upload_command
    run remotely('cd jukebox', 'bundle install --local --deployment', restart_command)
  end

  desc 'restart', 'Restart the jukebox process'
  def restart
    run remotely(restart_command)
  end

  class Network < Pi
    desc 'wifi', 'Set raspberry pi on wifi network mode'
    def wifi
      run remotely(copy_command('/etc/network/interfaces.wifi', '/etc/network/interfaces'))
      invoke :reboot
    end

    desc 'adhoc', 'Set raspberry pi on wifi network mode'
    def adhoc
      run remotely(copy_command('/etc/network/interfaces.adhoc', '/etc/network/interfaces'))
      invoke :reboot
    end
  end

  class Audio < Pi
    desc 'devices', 'Lists the audio devices available to the raspberry pi'
    def devices
      run(remotely('cd jukebox', 'thor local:audio:devices'))
    end
  end
end

class Local < Thor
  include Commands
  include Thor::Actions

  desc 'console', 'Spawns a console'
  def console
    exec console_command
  end

  class Audio < Local
    desc 'devices', 'Lists the audio devices available to the local machine'
    def devices
      require 'audio-playback'
      say Hirb::Helpers::AutoTable.render (AudioPlayback::Device::Output.all.map { |d| { id: d.id, name: d.name }} )
    end
  end
end

class Library < Thor
  desc 'sync', 'Synchronizes local song library with the manifest'
  def sync
    ::Library.synchronize
  end

  desc 'list', 'Lists all songs in the library'
  def list
    say Hirb::Helpers::AutoTable.render(::Library.list)
  end
end

class Jukebox < Thor
  include Commands
  include Thor::Actions

  desc 'logs', 'Tails the jukebox process logs'
  def logs
    run remotely('sudo tail -f -n 200 /var/log/upstart/jukebox.log')
  end

  desc 'song', 'Plays song on running jukebox server in raspberry pi'
  def play_song(id)
    put jukebox_url("/play/song/#{id}")
  end

  desc 'stop', 'Plays song on running jukebox server in raspberry pi'
  def stop(id)
    put jukebox_url("/stop")
  end

  no_commands do
    def jukebox_url(path = '/')
      URI::HTTP.build(host: ENV['PI_HOSTNAME'], port: ENV['CONTROL_PORT'], path: path).to_s
    end

    def put(url)
      RestClient.put(url, {})
    end
  end
end