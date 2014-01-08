require_relative '../helper'

describe Geotrigger::Device do

  let :dev do
    s = Geotrigger::AGO::Session.new client_id: CONF[:client_id],
                                     type: :device

    # can't use this because Geotrigger doesn't know it yet
    #
    ago_did = s.device_data['deviceId']

    # make a call to Geotrigger so it learns of new device
    #
    at = s.access_token
    r = HTTPClient.new.get Geotrigger::Session::BASE_URL % 'device/list',
                           nil,
                           'Authorization' => "Bearer #{at}"

    gt_did = JSON.parse(r.body)['devices'][0]['deviceId']

    # assert ids are the same
    #
    ago_did.should eq gt_did

    Geotrigger::Device.new client_id: CONF[:client_id],
                   client_secret: CONF[:client_secret],
                   device_id: ago_did
  end

  it 'fetches tags' do
    ts = dev.tags
    ts.should_not be nil
    ts.should be_a Array
    ts.first.should be_a Geotrigger::Tag
    ts.first.name.should eq dev.default_tag
  end

  it 'knows the default tag' do
    dev.default_tag =~ /^device:\S+$/
  end

  it 'updates' do
    dev.properties = {'foo' => 'bar'}
    dev.trackingProfile = 'adaptive'
    dev.save
    dev.properties.should eq({'foo' => 'bar'})
    dev.trackingProfile.should eq 'adaptive'
  end

  it 'adds tags' do
    ts = dev.tags
    ts.length.should eq 1
    dev.add_tags 'foo', 'bar'
    dev.save
    ts = dev.tags
    ts.length.should eq 3
  end

  it 'sets tags' do
    ts = dev.tags
    ts.length.should eq 1
    dev.tags = dev.default_tag, 'fu', 'bat'
    dev.save
    ts = dev.tags
    ts.length.should eq 3
  end

  it 'removes tags' do
    dev.tags = dev.default_tag, 'fizz', 'buzz'
    dev.save
    sleep 3
    ts = dev.tags
    ts.length.should eq 3
    dev.remove_tags 'fizz', 'buzz'
    dev.save
    ts = dev.tags
    ts.length.should eq 1
  end

end
