class Song < ActiveRecord::Base

  serialize :chords, JSON

  validates :key, presence: true, uniqueness: true

  scope :need_processing, -> { where('chords IS ? OR title IS ?', nil, nil) }

  before_destroy { delete_file! }

  def metadata?
    chords? && title?
  end

  def process!
    fetch_metadata!
    ensure_download!
  end

  def fetch_metadata!
    unless metadata?
      self.title = info.title
      self.chords = Chordify.fetch!(info.video_id)['song']['chords']
      self.save
    end
  end

  def ensure_download!
    download! unless file_exists?
  end

  def download!
    # extract_audio will create an mp3 file and delete the original video=
    YoutubeDL.download url, {
      prefer_ffmpeg: "true",
      extract_audio: "true",
      audio_format: "mp3",
      audio_quality: "0",
      # Audite expects a 44,100 sample rate, 2 channels
      postprocessor_args: '-ar 44100 -ac 2',
      output: temporary_path
    }
  end

  def info
    @info ||= VideoInfo.new(url)
  end

  def url
    "https://www.youtube.com/watch?v=#{key}"
  end

  def file_exists?
    metadata? && File.exists?(path)
  end

  def filename(extension)
    "#{title.parameterize}-#{key}.#{extension}"
  end

  def delete_file!
    File.delete(path) if file_exists?
  end

  def path(extension: 'mp3')
    File.join(Library::DIRECTORY, filename(extension))
  end

  def temporary_path
    path(extension: 'mp4')
  end

  def as_json(*args)
    {
      id: id,
      title: title,
      url: url
    }
  end

end