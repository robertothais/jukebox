class Chordify
  @@login_cookies = nil
  @@library = nil

  def self.login!
    return @@login_cookies if @@login_cookies

    @@login_cookies = RestClient.post('https://chordify.net/user/signin', email:    ENV['CHORDIFY_ACCOUNT_EMAIL'],
                                                                          password: ENV['CHORDIFY_ACCOUNT_PASSWORD']) do |resp, _req, _res|
      raise "Expected response code 302!  Got #{resp.code}" unless resp.code == 302
      resp.cookies
    end
  end

  def self.fetch!(youtube_id, max_retries = 4)
    login!
    post_song_response = RestClient.post('https://chordify.net/song', { url: "https://www.youtube.com/watch?v=#{youtube_id}", pseudoId: "youtube:#{youtube_id}" }, cookies: @@login_cookies)
    post_song_response_parsed = JSON.parse(post_song_response)

    if post_song_response_parsed['status'] == 'error'
      raise "Encountered error - response: #{post_song_response_parsed.inspect}"
    elsif post_song_response_parsed['status'] == 'inqueue' || post_song_response_parsed['status'] == 'processing'
      if max_retries > 0
        sleep_time = 8
        sleep(sleep_time)
        fetch!(youtube_id, max_retries - 1)
      else
        raise "Still in queue and out of retries!  #{post_song_response_parsed.inspect}"
      end
    elsif post_song_response_parsed['status'] == 'done'
      slug = post_song_response_parsed['slug']
      data_response = RestClient.get("https://chordify.net/song/getdata//#{slug}", cookies: @@login_cookies)
      JSON.parse(data_response)
    else
      false
    end
  end
end
