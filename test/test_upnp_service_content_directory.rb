require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'UPnP/service/content_directory'
require 'UPnP/test_utilities'

class TestUPnPServiceContentDirectory < Test::Unit::TestCase

  def setup
    socket = Object.new
    def socket.addr() ['AF_INET', '65432', '192.0.2.1', '192.0.2.1'] end
    Thread.current[:WEBrickSocket] = socket

    @temp_dir = File.join Dir.tmpdir, "test_upnp_content_directory_#{$$}"
    FileUtils.mkdir_p @temp_dir

    FileUtils.mkdir_p File.join(@temp_dir, 'Movies')
    FileUtils.mkdir_p File.join(@temp_dir, 'Music')
    FileUtils.mkdir_p File.join(@temp_dir, 'Pictures')

    @old_pwd = Dir.pwd
    Dir.chdir @temp_dir

    @device = UPnP::Device.new 'TestDevice', 'test device'
    @cd = UPnP::Service::ContentDirectory.new @device, 'ContentDirectory'
  end

  def teardown
    Thread.current[:WEBrickSocket] = nil
    FileUtils.rm_rf @temp_dir
    Dir.chdir @old_pwd
  end

  def test_Browse_item
    util_image

    result = @cd.Browse @pictures_id, 'BrowseMetadata', '', 0, 0, ''

    assert_equal nil, result.shift
    assert_match %r%<DIDL-Lite%, result.shift
    assert_equal 1, result.shift
    assert_equal 1, result.shift
    assert_equal 1, result.shift
    assert result.empty?
  end

  def test_GetSystemUpdateId
    assert_equal [nil, 0], @cd.GetSystemUpdateID
  end

  def test_add_object
    id = @cd.add_object 'Movies', 0

    assert_equal 1, id
    assert_equal 'Movies', @cd.get_object(id)
    assert_equal id, @cd.get_object('Movies')

    assert_equal 1, @cd.add_object('Movies', 0)
  end

  def test_add_directory
    @cd.add_directory 'Movies'

    assert_equal 1, @cd.get_object('Movies')
    assert_equal 1, @cd.system_update_id
  end

  def test_children_result
    @cd.add_directory 'Movies'
    @cd.add_directory 'Pictures'
    @cd.add_directory 'Music'

    result = @cd.children_result(0)

    assert_equal 3, result.shift
    assert_equal 3, result.shift

    expected = [
      { :container => [
        { 'restricted' => 'true', 'childCount' => '0', 'id' => '1',
          'parentID' => '0' },
        { :title => 'Movies', :class => 'object.container' }
        ]
      },
      { :container => [
        { 'restricted' => 'true', 'childCount' => '0', 'id' => '3',
          'parentID' => '0' },
        { :title => 'Music', :class => 'object.container' }
        ]
      },
      { :container => [
        { 'restricted' => 'true', 'childCount' => '0', 'id' => '2',
          'parentID' => '0' },
        { :title => 'Pictures', :class => 'object.container' }
        ]
      }
    ]

    assert_equal expected, util_didl(result.shift)
  end

  def test_dlna_profile
    assert_equal 'DLNA.ORG_PN=MP3', @cd.dlna_profile('audio/mpeg')
    assert_equal 'DLNA.ORG_PN=JPEG_LRG', @cd.dlna_profile('image/jpeg')
    assert_equal nil, @cd.dlna_profile('application/octet-stream')
  end

  def test_get_object
    assert_raise UPnP::Service::ContentDirectory::Error do
      @cd.get_object 'Movies'
    end

    assert_equal 1, @cd.get_object('Movies', 0)
    assert_equal 1, @cd.get_object('Movies')
    assert_equal 'Movies', @cd.get_object(1)
  end

  def test_get_parent
    assert_raise UPnP::Service::ContentDirectory::Error do
      @cd.get_parent 'Movies'
    end

    id = @cd.add_object 'Movies', 0

    assert_equal 0, @cd.get_parent(id)
  end

  def test_item_class
    assert_equal 'object.item.audioItem', @cd.item_class('audio/mpeg')
    assert_equal 'object.item.imageItem', @cd.item_class('image/jpeg')
    assert_equal 'object.item.videoItem', @cd.item_class('video/mpeg')
    assert_equal 'object.item.textItem',  @cd.item_class('text/plain')
    assert_equal 'object.item', @cd.item_class('application/octet-stream')
  end

  def test_make_result
    result = @cd.make_result do end

    expected = <<-EOF
<DIDL-Lite xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\">
</DIDL-Lite>
    EOF

    assert_equal expected, result
  end

  def test_metadata_result
    @cd.add_directory 'Movies'

    result = @cd.metadata_result @cd.get_object('Movies')

    expected = [
      { :container => [
        { 'restricted' => 'true', 'childCount' => '0', 'id' => '1',
          'parentID' => '0' },
        { :title => 'Movies', :class => 'object.container' }
        ]
      }
    ]

    assert_equal expected, util_didl(result)
  end

  def test_mount_extra
    server = Object.new
    server.instance_variable_set :@args, []
    def server.mount(path, servlet, root)
      @args << [path, servlet, root]
    end

    @cd.add_directory 'Music'

    @cd.mount_extra server

    args = server.instance_variable_get :@args

    expected = [
      ['/TestDevice/ContentDirectory/1', WEBrick::HTTPServlet::FileHandler,
       'Music'],
      ['/TestDevice/ContentDirectory/album_art',
       UPnP::Service::ContentDirectory::AlbumArtHandler, @cd],
      ['/TestDevice/ContentDirectory/thumbnails',
       UPnP::Service::ContentDirectory::ThumbnailHandler, @cd],
    ]

    assert_equal expected, args
  end

  def test_resource_audio
    util_audio
    stat = File.stat @audio_name

    xml = util_builder

    @cd.resource xml, 'Music/audio.mp3', 'audio/mpeg', stat

    expected = [
      [
        :res, {
          :protocolInfo => 'http-get:*:audio/mpeg:DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_CI=0',
          :size => 0
        },
        'http://192.0.2.1:65432/TestDevice/ContentDirectory/1/audio.mp3'
      ]
    ]

    assert_equal expected, xml._elements
  end

  def test_resource_image
    util_image
    stat = File.stat @image_name

    xml = util_builder

    @cd.resource xml, @image_name, 'image/png', stat

    expected = [
      [
        :res, {
          :protocolInfo => 'http-get:*:image/png:DLNA.ORG_OP=01;DLNA.ORG_CI=0',
          :size => 0
        },
        'http://192.0.2.1:65432/TestDevice/ContentDirectory/1/image.png'
      ]
    ]

    assert_equal expected, xml._elements
  end

  def test_resource_video
    util_video
    stat = File.stat @video_name

    xml = util_builder

    @cd.resource xml, @video_name, 'video/mp4', stat

    expected = [
      [
        :res, {
          :protocolInfo => 'http-get:*:video/mp4:DLNA.ORG_OP=01;DLNA.ORG_CI=0',
          :size => 0
        },
        'http://192.0.2.1:65432/TestDevice/ContentDirectory/1/video.mp4'
      ]
    ]

    assert_equal expected, xml._elements
  end

  def test_resource_url
    util_image

    assert_equal 'http://192.0.2.1:65432/TestDevice/ContentDirectory/1/image.png',
                 @cd.resource_url(@image_name)
  end

  def test_result_container
    util_audio

    xml = util_builder

    @cd.result_container xml, @music_id, 5, 'Music'

    expected = [
      ['container',
        { :childCount => 5, :parentID => 0, :id => 1, :restricted => true }],
      [:dc, :title, 'Music'],
      [:upnp, :class, 'object.container'],
    ]

    assert_equal expected, xml._elements
  end

  def test_result_item
    util_audio

    xml = util_builder

    @cd.result_item xml, @audio_id, 'audio.mp3'

    expected = [
      ['item',
        { :childCount => 0, :parentID => 1, :restricted => true, :id => 2 }],
      [:upnp, :class, 'object.item'],
      [:dc, :title, 'audio.mp3'],
      [:dc, :date, File.stat(@audio_name).ctime.iso8601],
      [:res, {
        :protocolInfo => 'http-get:*:regular file:DLNA.ORG_OP=01;DLNA.ORG_CI=0',
        :size => 0 },
       'http://192.0.2.1:65432/TestDevice/ContentDirectory/1/audio.mp3']
    ]

    assert_equal expected, xml._elements
  end

  def test_result_object_container
    util_audio

    xml = util_builder

    @cd.result_object xml, @music_id, 'Music'

    expected = [
      ['container',
        { :childCount => 1, :parentID => 0, :id => 1, :restricted => true }],
      [:dc, :title, 'Music'],
      [:upnp, :class, 'object.container'],
    ]

    assert_equal expected, xml._elements
  end

  def test_result_object_item
    util_audio

    xml = util_builder

    @cd.result_object xml, @audio_id, 'audio.mp3'

    expected = [
      ['item',
        { :childCount => 0, :parentID => 1, :id => 2, :restricted => true }],
      [:upnp, :class, 'object.item'],
      [:dc, :title, 'audio.mp3'],
      [:dc, :date, File.stat(@audio_name).ctime.iso8601],
      [:res,
        { :protocolInfo =>
          'http-get:*:regular file:DLNA.ORG_OP=01;DLNA.ORG_CI=0',
          :size => 0 },
       'http://192.0.2.1:65432/TestDevice/ContentDirectory/1/audio.mp3']
    ]

    assert_equal expected, xml._elements
  end

  def test_result_object_root
    util_audio
    util_image
    util_video

    xml = util_builder

    @cd.result_object xml, 0, 'Root'

    expected = [
      [ 'container',
        { :childCount => 3, :parentID => -1, :id => 0, :restricted => true }],
      [:dc, :title, 'Root'],
      [:upnp, :class, 'object.container'],
    ]

    assert_equal expected, xml._elements
  end

  def test_root_for
    @picture_id = util_image

    assert_equal 'Pictures', @cd.root_for(@picture_id)
  end

  def test_update_mtime
    util_audio
    assert_equal 1, @cd.system_update_id

    update_id = @cd.update_mtime @cd.get_object('Music')
    assert_equal 1, update_id
    assert_equal 2, @cd.system_update_id

    update_id = @cd.update_mtime @cd.get_object('Music')
    assert_equal nil, update_id
    assert_equal 2, @cd.system_update_id
  end

  def util_audio
    @cd.add_directory 'Music'
    @music_id = @cd.get_object 'Music'
    @audio_name = File.join 'Music', 'audio.mp3'

    FileUtils.touch @audio_name

    @audio_id = @cd.add_object @audio_name, @music_id
  end

  def util_builder
    xml = Object.new

    xml.instance_variable_set :@elements, []

    def xml.tag!(*args)
      @elements << args
      yield
    end

    def xml._elements
      @elements
    end
    
    def xml.method_missing(*args)
      @elements << args
    end

    xml
  end

  def util_didl(xml)
    didl = []

    xml = REXML::Document.new xml

    xml.each_element '//DIDL-Lite/*' do |e|
      obj = {}
      children = []
      children << Hash[*e.attributes.map { |n, v| [n, v] }.flatten]

      obj[e.name.intern] = children
      child_values = e.elements.map do |child|
        [child.name.intern, child.text.strip] 
      end

      children << Hash[*child_values.flatten]

      didl << obj
    end

    didl
  end

  def util_image
    @cd.add_directory 'Pictures'
    @pictures_id = @cd.get_object 'Pictures'
    @image_name = File.join 'Pictures', 'image.png'

    FileUtils.touch @image_name

    @image_id = @cd.add_object @image_name, @pictures_id
  end

  def util_video
    @cd.add_directory 'Movies'
    @movies_id = @cd.get_object 'Movies'
    @video_name = File.join 'Movies', 'video.mp4'

    FileUtils.touch @video_name

    @video_id = @cd.add_object @video_name, @movies_id
  end

end

