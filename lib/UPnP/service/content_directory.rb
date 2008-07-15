require 'rubygems'
require 'UPnP/service'

class UPnP::Service::ContentDirectory < UPnP::Service

  VERSION = '1.0'

  ##
  # Returns the searching capabilities supported by the device

  add_action 'GetSearchCapabilities',
    [OUT, 'SearchCaps', 'SearchCapabilities']

  ##
  # Returns the CSV list of metadata tags that can be used in sortCriteria

  add_action 'GetSortCapabilities',
    [OUT, 'SortCaps', 'SortCapabilities']

  add_action 'GetSystemUpdateID',
    [OUT, 'Id', 'SystemUpdateID']

  add_action 'Browse',
    [IN, 'ObjectID',       'A_ARG_TYPE_ObjectID'],
    [IN, 'BrowseFlag',     'A_ARG_TYPE_BrowseFlag'],
    [IN, 'Filter',         'A_ARG_TYPE_Filter'],
    [IN, 'StartingIndex',  'A_ARG_TYPE_Index'],
    [IN, 'RequestedCount', 'A_ARG_TYPE_Count'],
    [IN, 'SortCriteria',   'A_ARG_TYPE_SortCriteria'],

    [OUT, 'Result',         'A_ARG_TYPE_Result'],
    [OUT, 'NumberReturned', 'A_ARG_TYPE_Count'],
    [OUT, 'TotalMatches',   'A_ARG_TYPE_Count'],
    [OUT, 'UpdateID',       'A_ARG_TYPE_UpdateID']

  # optional actions

  add_action 'Search',
    [IN, 'ContainerID', 'A_ARG_TYPE_ObjectID'],
    [IN, 'SearchCriteria', 'A_ARG_TYPE_SearchCriteria'],
    [IN, 'Filter', 'A_ARG_TYPE_Filter'],
    [IN, 'StartingIndex', 'A_ARG_TYPE_Index'],
    [IN, 'RequestedCount', 'A_ARG_TYPE_Count'],
    [IN, 'SortCriteria', 'A_ARG_TYPE_SortCriteria'],

    [OUT, 'Result', 'A_ARG_TYPE_Result'],
    [OUT, 'NumberReturned', 'A_ARG_TYPE_Count'],
    [OUT, 'TotalMatches', 'A_ARG_TYPE_Count'],
    [OUT, 'UpdateID', 'A_ARG_TYPE_UpdateID']

  add_action 'CreateObject',
    [IN, 'ContainerID', 'A_ARG_TYPE_ObjectID'],
    [IN, 'Elements', 'A_ARG_TYPE_Result'],

    [OUT, 'ObjectID', 'A_ARG_TYPE_ObjectID'],
    [OUT, 'Result', 'A_ARG_TYPE_Result']

  add_action 'DestroyObject',
    [IN, 'ObjectID', 'A_ARG_TYPE_ObjectID']

  add_action 'UpdateObject',
    [IN, 'ObjectID', 'A_ARG_TYPE_ObjectID'],
    [IN, 'CurrentTagValue', 'A_ARG_TYPE_TagValueList'],
    [IN, 'NewTagValue', 'A_ARG_TYPE_TagValueList']

  add_action 'ImportResource',
    [IN, 'SourceURI', 'A_ARG_TYPE_URI'],
    [IN, 'DestinationURI', 'A_ARG_TYPE_URI'],

    [OUT, 'TransferID', 'A_ARG_TYPE_TransferID']

  add_action 'ExportResource',
    [IN, 'SourceURI', 'A_ARG_TYPE_URI'],
    [IN, 'DestinationURI', 'A_ARG_TYPE_URI'],

    [OUT, 'TransferID', 'A_ARG_TYPE_TransferID']

  add_action 'StopTransferResource',
    [IN, 'TransferID', 'A_ARG_TYPE_TransferID']

  add_action 'GetTransferProgress',
    [IN, 'TransferID', 'A_ARG_TYPE_TransferID'],

    [OUT, 'TransferStatus', 'A_ARG_TYPE_TransferStatus'],
    [OUT, 'TransferLength', 'A_ARG_TYPE_TransferLength'],
    [OUT, 'TransferTotal', 'A_ARG_TYPE_TransferTotal']

  add_action 'DeleteResource',
    [IN, 'ResourceURI', 'A_ARG_TYPE_URI']

  add_action 'CreateReference',
    [IN, 'ContainerID', 'A_ARG_TYPE_ObjectID'],
    [IN, 'ObjectID', 'A_ARG_TYPE_ObjectID'],
    [OUT, 'NewID', 'A_ARG_TYPE_ObjectID']

  add_variable 'TransferIDs',               'string', nil, nil, true
  add_variable 'A_ARG_TYPE_ObjectID',       'string'
  add_variable 'A_ARG_TYPE_Result',         'string' # 2.5.4 - DIDL-Lite
  add_variable 'A_ARG_TYPE_SearchCriteria', 'string' # 2.5.5
  add_variable 'A_ARG_TYPE_BrowseFlag',     'string',
               %w[BrowseMetadata BrowseDirectChildren]
  add_variable 'A_ARG_TYPE_Filter',         'string' # 2.5.7
  add_variable 'A_ARG_TYPE_SortCriteria',   'string' # 2.5.8
  add_variable 'A_ARG_TYPE_Index',          'ui4'    # 2.5.9
  add_variable 'A_ARG_TYPE_Count',          'ui4'    # 2.5.10
  add_variable 'A_ARG_TYPE_UpdateID',       'ui4'    # 2.5.11
  add_variable 'A_ARG_Type_TransferID',     'ui4'    # 2.5.12
  add_variable 'A_ARG_Type_TransferStatus', 'string' # 2.5.13
  add_variable 'A_ARG_Type_TransferLength', 'string' # 2.5.14
  add_variable 'A_ARG_Type_TransferTotal',  'string' # 2.5.15
  add_variable 'A_ARG_TYPE_TagValueList',   'string' # 2.5.16
  add_variable 'A_ARG_TYPE_URI',            'uri'    # 2.5.17
  add_variable 'SearchCapabilities',        'string' # 2.5.18
  add_variable 'SortCapabilities',          'string' # 2.5.19
  add_variable 'SystemUpdateID',            'ui4',    nil, nil, true # 2.5.20
  add_variable 'ContainerUpdateIDs',        'string', nil, nil, true # 2.5.21

  def on_init
    @SystemUpdateID = 0
    @root = '/Users/drbrain/Pictures'

    @objects = {}
    @objects[0] = @root

    @parents = {}
    @parents[0] = -1
  end

  ##
  # Allows the caller to incrementally browse the hierarchy of the content
  # directory, including information listing the classes of objects available
  # in any container.

  def Browse(object_id, browse_flag, filter, starting_index, requested_count,
             sort_criteria)
    filter = filter.split ','
    object_id = object_id.to_i
    update_id = 0

    case browse_flag
    when 'BrowseMetadata' then
      number_returned = 1
      total_matches = 1

      result = metadata_result object_id
    when 'BrowseDirectChildren' then
      number_returned, total_matches, result = children_result object_id
    else
      raise "unknown BrowseFlag #{browse_flag}"
    end

    [nil, result, number_returned, total_matches, update_id]
  end

  ##
  # Returns the current value of the SystemUpdateID state variable.  For use
  # by clients that want to poll for any changes in the content directory
  # instead of subscribing to events.

  def GetSystemUpdateID
    [nil, @SystemUpdateID]
  end

  def children_result(object_id)
    object = @objects[object_id]

    children = Dir[File.join(object, '*')]

    result = make_result do |xml|
      children.each do |child|
        stat = File.stat child
        @objects[stat.ino] = child
        @parents[stat.ino] = object_id

        result_object xml, child, stat.ino, File.basename(child)
      end
    end

    [children.length, children.length, result]
  end

  def item_class(mime_type)
    case mime_type
    when /^image/ then
      'object.item.imageItem'
    else
      puts "unhandled mime type #{mime_type}"
      'object.item'
    end
  end

  def make_result
    result = []

    xml = Builder::XmlMarkup.new :indent => 2, :target => result
    xml.tag! 'DIDL-Lite',
             'xmlns' => 'urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/',
             'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
             'xmlns:upnp' => 'urn:schemas-upnp-org:metadata-1-0/upnp/' do
      yield xml
    end

    result.join
  end

  def metadata_result(object_id)
    object = @objects[object_id]
    parent = @parents[object_id]

    title = object == 0 ? 'root' : File.basename(object)

    make_result do |xml|
      result_object xml, object, object_id, title
    end
  end

  def mount_extra(http_server)
    super

    path = File.join service_path, 'root'

    http_server.mount path, WEBrick::HTTPServlet::FileHandler, @root
  end

  def resource(xml, object, mime_type)
    info = nil
    url = nil

    case mime_type
    when 'image/jpeg' then
      info = [
        'http-get', '*', mime_type,
        'DLNA.ORG_PN=JPEG_LRG;DLNA.ORG_OP=01;DLNA.org_CI=0'
      ].join ':'
      url = resource_url object
    end

    xml.res({ :protocolInfo => info }, url) if info and url
  end

  ##
  # A URL to this object on this server.  Correctly handles multi-homed
  # servers.

  def resource_url(object)
    _, port, host, addr = Thread.current[:WEBrickSocket].addr

    object = object.sub @root, ''

    File.join "http://#{addr}:#{port}", service_path, 'root', object
  end

  def result_object(xml, object, object_id, title)
    if File.directory? object then
      children = Dir[File.join(object, '*/')].length

      result_container xml, object, object_id, children, title
    else
      result_item xml, object, object_id, title
    end
  end

  def result_container(xml, object, object_id, children, title)
    parent = @parents[object_id]

    xml.tag! 'container', :id => object_id, :parentID => parent,
                   :restricted => true, :childCount => children do
      xml.dc :title, title
      xml.upnp :class, 'object.container'
    end
  end

  def result_item(xml, object, object_id, title)
    parent = @parents[object_id]

    `file -I #{object}` =~ /(\S+\/\S+)$/
    mime_type = $1

    xml.tag! 'item', :id => object_id, :parentID => parent,
                   :restricted => true, :childCount => 0 do
      xml.dc :title, title
      xml.upnp :class, item_class(mime_type)

      resource xml, object, mime_type
    end
  end

end

