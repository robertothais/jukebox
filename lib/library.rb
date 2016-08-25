require 'open-uri'

class Library

  DIRECTORY = File.join(ROOT_DIR, 'songs')

  def self.synchronize
    library = self.new
    library.create_all
    library.process_all
    library.prune
  end

  def self.list
    Song.select(:id, :title, :key).all
  end

  def initialize
    # File or URL
    # The manifest should be a hash of hashes. The child hashes
    # should contain the a key named 'key' with value set to the YouTube key
    @manifest = JSON.parse(open(ENV['SONGS_MANIFEST']).read)
  end

  def keys
    @manifest.map { |_, v| v['key'] }
  end

  def create_all
    keys.each { |key| Song.where(key: key).first_or_create! }
  end

  def process_all
    Song.all.where(key: keys).each do |song|
      SpinningCursor.run do
        banner '[ ' + 'Processing'.color(:yellow) + ' ]' + " #{song.title || song.info.title}"
        type :spinner
        context = self
        action do
          begin
            song.process!
            context.message  '[ ' + 'Done'.color(:green) + ' ]' + " #{song.title || song.info.title}"
          rescue
            context.message  '[ ' + 'Error'.color(:red) + ' ]' + " #{song.title || song.info.title}"
          end
        end
      end
    end
  end

  def prune
    prune_records
    prune_files
  end

  def prune_records
    orphans = Song.where('key NOT IN (?)', keys)
    incomplete = Song.need_processing
    (orphans + incomplete).each do |song|
      song.destroy
      puts '[ ' + 'Removed'.color(:red) + ' ]' + " #{song.title || song.key}"
    end
  end

  def prune_files
    files = Dir[File.join(DIRECTORY, '/*mp3')]
    files.delete_if do |file|
      keys.map { |k| Regexp.new(k) }.any? { |r| file =~ r }
    end
    files.each do |file|
      File.delete(file)
      puts '[ ' + 'Deleted'.color(:red) + ' ]' + " #{file}"
    end
  end

end