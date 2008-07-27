require 'test/unit'
require 'UPnP/service/content_directory'

class TestUPnPServiceContentDirectory < Test::Unit::TestCase

  def setup
    socket = Object.new
    def socket.addr() ['AF_INET', '65432', '192.0.2.1', '192.0.2.1'] end
    Thread.current[:WEBrickSocket] = socket

    @cd = UPnP::Service::ContentDirectory.new nil, 'ContentDirectory'
  end

  def teardown
    Thread.current[:WEBrickSocket] = nil
  end

  def test_add_object
    id = @cd.add_object 'Movies', 0

    assert_equal 1, id
    assert_equal 'Movies', @cd.get_object(id)
    assert_equal id, @cd.get_object('Movies')
  end

  def test_add_directory
    @cd.add_directory 'Movies'

    assert_equal 1, @cd.get_object('Movies')
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

  def test_resource_url
    util_picture

    assert_equal 'http://192.0.2.1:65432/ContentDirectory/1/pic.png',
                 @cd.resource_url(@picture_name)
  end

  def test_root_for
    @picture_id = util_picture

    assert_equal 'Pictures', @cd.root_for(@picture_id)
  end

  def util_picture
    @cd.add_directory 'Pictures'
    @pictures_id = @cd.get_object 'Pictures'
    @picture_name = 'pic.png'
    @picture_id = @cd.add_object @picture_name, @pictures_id
  end

end

