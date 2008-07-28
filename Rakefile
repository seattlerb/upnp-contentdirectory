# -*- ruby -*-

require 'rubygems'
require 'hoe'

$LOAD_PATH.unshift 'lib'
require 'UPnP/service/content_directory'

Hoe.new 'UPnP-ContentDirectory', UPnP::Service::ContentDirectory::VERSION do |p|
  p.rubyforge_name = 'seattlerb'
  p.developer 'Eric Hodel', 'drbrain@segment7.net'

  p.extra_deps << ['UPnP', '>= 1.2.0']
  p.extra_deps << ['builder', '>= 2.1.2']
  p.extra_deps << ['ruby-mp3info', '>= 0.6.7']
end

# vim: syntax=Ruby
