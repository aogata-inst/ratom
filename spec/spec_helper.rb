# Copyright (c) 2008 The Kaphan Foundation
#
# For licensing information see LICENSE.
#
# Please visit http://www.peerworks.org/contact for further information.
#

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'atom'

RSpec.configure do |config|

  def mock_response(klass, body, headers = {})
    response = klass.new(nil, nil, nil)
    allow(response).to receive(:body).and_return(body)
    
    headers.each do |k, v|
      allow(response).to receive(:[]).with(k).and_return(v)
    end
    
    response
  end
  
  def mock_http_get(url, response, user = nil, pass = nil)
    req = double('request')
    expect(Net::HTTP::Get).to receive(:new).with(url.request_uri).and_return(req)
    
    if user && pass
      expect(req).to receive(:basic_auth).with(user, pass)
    end
    
    http = double('http')
    expect(http).to receive(:request).with(req).and_return(response)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:ca_path=)
    allow(http).to receive(:verify_mode=)
    allow(http).to receive(:verify_depth=)
    expect(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(http)
  end
end
