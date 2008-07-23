= UPnP-ContentDirectory

* http://seattlerb.org/UPnP-ContentDirectory
* http://upnp.org
* Bugs: http://rubyforge.org/tracker/?func=add&group_id=1513&atid=5921

== DESCRIPTION:

A UPnP ContentDirectory service with some DLNA extensions.  Currently this is
a work in progress, and is only adequate for viewing images on a PlayStation
3.

== FEATURES/PROBLEMS:

* Only direct filesystem representations currently supported
* Largely undocumented
* Only tested on PlayStation 3
* Only images known to work
* Partially implemented:
  * Browse
  * GetSystemUpdateID
* Not implemented:
  * CreateObject
  * CreateReference
  * DeleteResource
  * DestroyObject
  * ExportResource
  * GetSearchCapabilities
  * GetSortCapabilities
  * GetTransferProgress
  * ImportResource
  * Search
  * StopTransferResource
  * UpdateObject

== SYNOPSIS:

In a UPnP::Device::create block:

  your_device.add_service 'ContentDirectory' do |cd|
    cd.add_directory Dir.pwd
  end

See UPnP::Device::MediaServer for an example of usage.

== REQUIREMENTS:

* A filesystem with files on it
* A UPnP MediaServer control point

== INSTALL:

  sudo gem install UPnP-ContentDirectory

== LICENSE:

Copyright 2008 Eric Hodel.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the names of the authors nor the names of their contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

