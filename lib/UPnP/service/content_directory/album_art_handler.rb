require 'rubygems'
require 'fileutils'
require 'mp3info'
require 'pathname'
require 'webrick/httpservlet/abstract'
require 'webrick/httpservlet/filehandler'
require 'UPnP/service/content_directory'

class UPnP::Service::ContentDirectory::AlbumArtHandler <
      WEBrick::HTTPServlet::AbstractServlet

  FileHandler = WEBrick::HTTPServlet::DefaultFileHandler

  def initialize(server, content_directory)
    @cd = content_directory
    @cache_dir = File.join @cd.cache_dir, 'album_art'
    FileUtils.mkdir_p @cache_dir

    @album_art_path = Pathname.new @cd.album_art_path

    super
  end

  def do_GET(req, res)
    mp3 = Pathname.new(req.path).relative_path_from(@album_art_path).to_s
    album_art = File.join @cache_dir, mp3

    mp3 = File.join '', mp3

    files = Dir["#{album_art}.*"]

    if files.length > 0 then
      album_art = files.first
      return serve_content req, res, album_art
    end

    Mp3Info.open mp3 do |info|
      image = info.tag2['APIC']
      raise WEBrick::HTTPStatus::NotFound, "`#{mp3}' has no album art" if
        image.nil?

      image =~ /\A.(.*?)\0..*?\0/m

      mime_type = $1
      data = $'

      case mime_type
      when 'image/png'  then album_art << '.png'
      when 'image/jpeg' then album_art << '.jpeg'
      end

      FileUtils.mkdir_p File.dirname(album_art)

      open album_art, 'wb' do |io|
        io.write data
      end
    end

    serve_content req, res, album_art

  rescue Mp3InfoError
    raise WEBrick::HTTPStatus::NotFound, "object #{mp3} is not an MP3"
  rescue UPnP::Service::ContentDirectory::Error
    raise WEBrick::HTTPStatus::NotFound, "object #{mp3} not found"
  end

  def serve_content(req, res, album_art)
    handler = FileHandler.get_instance @config, album_art
    handler.service req, res
  end

end
