require_relative '../helper'

describe Geotrigger::Application do

  PERMS = 'deviceList',
          'deviceLocation',
          'deviceTagging',
          'deviceToken',
          'discoverableDevice',
          'discoverableApplication',
          'triggerApply',
          'triggerDelete',
          'triggerHistory',
          'triggerList',
          'triggerUpdate'

  let :app do
    Geotrigger::Application.new client_id: CONF[:client_id],
                                client_secret: CONF[:client_secret]
  end

  it 'fetches permissions' do
    ps = app.permissions
    ps.should_not be nil
    ps.should be_a Hash
    ps.keys.should include *PERMS
  end

  it 'sets permissions' do
    PERMS.each do |p|
      ps = app.permissions
      _ps = ps.merge p => !ps[p]
      app.permissions = _ps
      __ps = app.permissions
      __ps.should eq ps.merge(p => !ps[p])
      app.permissions = ps
    end
  end

  it 'fetches devices' do
    ds = app.devices
    ds.should_not be nil
    ds.should be_a Array
    ds.first.should be_a Geotrigger::Device unless ds.empty?
  end

  it 'fetches tags' do
    ts = app.tags
    ts.should_not be nil
    ts.should be_a Array
    ts.first.should be_a Geotrigger::Tag unless ts.empty?
  end

  it 'fetches triggers' do
    ts = app.triggers
    ts.should_not be nil
    ts.should be_a Array
    ts.first.should be_a Geotrigger::Trigger unless ts.empty?
  end

end
