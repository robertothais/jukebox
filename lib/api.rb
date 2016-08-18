class Jukebox::API < Sinatra::Base

  set :environment, ENV['JUKEBOX_ENV']
  set :port, ENV['CONTROL_PORT']

  use Rack::Runtime

  put /\/play\/index\/(1[0-2]|0?[1-9])$/ do
    Celluloid.publish 'song:pick_index', params[:captures].first.to_i
    status 200
  end

  put '/play/song/:id' do
    Celluloid.publish 'song:play', params[:id]
    status 200
  end

  put '/stop' do
    Celluloid.publish 'song:stop'
    status 200
  end

  put '/shuffle' do
    Celluloid.publish 'song:shuffle'
    status 200
  end

  put '/list' do
    Song.all.to_json
  end

end