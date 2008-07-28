require 'rubygems'
begin
  require 'image_science'
rescue LoadError
end

require 'fileutils'
require 'pathname'
require 'webrick/httpservlet/abstract'
require 'webrick/httpservlet/filehandler'
require 'UPnP/service/content_directory'

class UPnP::Service::ContentDirectory::ThumbnailHandler <
      WEBrick::HTTPServlet::AbstractServlet

  FileHandler = WEBrick::HTTPServlet::DefaultFileHandler

  def initialize(server, content_directory)
    @cd = content_directory
    @cache_dir = File.join @cd.cache_dir, 'thumbnails'
    FileUtils.mkdir_p @cache_dir

    @thumbnail_path = Pathname.new @cd.thumbnail_path

    super
  end

  def do_GET(req, res)
    image = Pathname.new(req.path).relative_path_from(@thumbnail_path).to_s
    thumbnail = File.join @cache_dir, image

    image = File.join '', image

    files = Dir["#{thumbnail}.jpeg"]

    if files.length > 0 then
      thumbnail = files.first
      return serve_content(req, res, thumbnail)
    end

    ImageScience.with_image image do |img|
      img.cropped_thumbnail 100 do |thumb|
        FileUtils.mkdir_p File.dirname(thumbnail)
        thumb.save thumbnail
      end
    end

    serve_content req, res, thumbnail

  rescue TypeError
    raise WEBrick::HTTPStatus::NotFound, "object #{image} is not an image"
  end

  def serve_content(req, res, album_art)
    handler = FileHandler.get_instance @config, album_art
    handler.service req, res
  end

end

