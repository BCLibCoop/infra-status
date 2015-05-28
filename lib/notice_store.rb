require 'yaml'
require 'date'
require 'active_support/time'
require 'singleton'

# Stores notices and caches them in memory.
# Automatically refreshes the cache after CACHE_SECONDS seconds.
class NoticeStore
  include Singleton
  CACHE_SECONDS = 60
  attr_reader :load_date

  def initialize
    update!
  end

  def update!
    @notices = []

    Dir.glob('data/notices/*.txt') do |file|
      begin
        @notices << Notice.from_file(file)
      rescue => e
        $stderr.puts 'Invalid notice (%s): %s' % [e.message, file]
      end
    end

    @notices.sort! { |a, b| b['created_at'] <=> a['created_at'] }

    @load_date = DateTime.now
  end

  def notices
    update?
    @notices
  end

  def visible_notices
    notices.select do |notice|
      is_active = notice['active']
      is_active &= notice['expire_at'] >= DateTime.now if notice.has_key? 'expire_at'
      is_active &= notice['created_at'] <= DateTime.now if notice.has_key? 'created_at'

      is_active
    end

  end

  def active_notices
    notices.select do |notice|
      is_active = notice['active']
      is_active &= notice['expire_at'] >= DateTime.now if notice.has_key? 'expire_at'
      is_active &= notice['created_at'] <= DateTime.now if notice.has_key? 'created_at'
      is_active &= notice['starts_at'] <= DateTime.now if notice.has_key? 'starts_at'

      is_active
    end
  end

  def notice_affects_service(notice, service)
      return (notice.has_key? 'affects' and not notice['affects'].nil? and notice['affects'].include? service)
  end

  def active_notices_for(service)
    active_notices.select do |notice|
      notice_affects_service(notice, service)
    end
  end

  def visible_notices_for(service)
    visible_notices.select do |notice|
      notice_affects_service(notice, service)
    end
  end

  def notice(id)
    notices.each do |notice|
      return notice if notice['id'] == id
    end

    nil
  end

  private
  def update?
    if ((DateTime.now - @load_date) * 60 * 60 * 24).to_i > CACHE_SECONDS
      update!
    end
  end
end

class Notice
  def self.from_file(filename)
    content = File.read(filename)
    metadata = YAML.load(content) || {}
    metadata['updated_at'] = File.mtime(filename)
    metadata['timezone'] = 'UTC' unless metadata.has_key? 'timezone'
    Time.zone = metadata['timezone']
    description = 'missing description'
    description_splitpos = nil

    lines = content.split("\n").map { |l| l.strip }
    if lines[0] == '---' and lines.grep('---').length() >= 2
        description_splitpos = 2
    elsif lines.grep('---').length() >= 1
        description_splitpos = 1
    else
        description_splitpos = 0
    end

    description = content.split('---')[description_splitpos].strip
    new(File.basename(filename, '.txt'), metadata, description)
  end

  def [](what)
    if @metadata.has_key? what
      @metadata[what]
    else
      nil
    end
  end

  def has_key?(what)
    @metadata.has_key? what
  end

  def get_content
    @content
  end

  def url
    MY_URL + 'notice/' + @metadata['id']
  end

  private
  def initialize(id, metadata, content)
    @metadata = metadata

    %w[created_at eta expire_at starts_at].each do |key|
      @metadata[key] = Time.zone.parse(@metadata[key]).in_time_zone(@metadata['timezone']) if @metadata.has_key? key
    end

    @metadata['id'] = id
    @content = content
  end
end
