require_relative '../helper'

describe Geotrigger::AGO::Session do

  def session_should_be_ok agos
    agos.access_token.should_not be nil
    agos.ago_data.should_not be nil
    agos.ago_data.keys.should include 'access_token', 'expires_in', :expires_at
    (agos.ago_data[:expires_at] > Time.now).should be true
  end

  it 'fetches an access token for client credentials' do
    session_should_be_ok Geotrigger::AGO::Session.new client_id: CONF[:client_id],
                                                      client_secret: CONF[:client_secret]
  end

  it 'fetches access and refresh tokens for client id' do
    session_should_be_ok Geotrigger::AGO::Session.new client_id: CONF[:client_id],
                                                      type: :device
  end

  it 'fetches access token for client id and refresh token' do
    session_should_be_ok Geotrigger::AGO::Session.new client_id: CONF[:client_id],
                                                      refresh_token: CONF[:refresh_token],
                                                      type: :device
  end

  it 'updates an expired access token with client credentials' do
    agos = Geotrigger::AGO::Session.new client_id: CONF[:client_id],
                                        client_secret: CONF[:client_secret]
    at = agos.access_token
    Timecop.travel agos.ago_data[:expires_at] do
      _at = agos.access_token
      session_should_be_ok agos
      at.should_not eq _at
    end
  end

  it 'updates an expired access token without given refresh token' do
    agos = Geotrigger::AGO::Session.new client_id: CONF[:client_id],
                                        type: :device
    at = agos.access_token
    Timecop.travel agos.ago_data[:expires_at] do
      _at = agos.access_token
      session_should_be_ok agos
      at.should_not eq _at
    end
  end

  it 'updates an expired access token given refresh token' do
    agos = Geotrigger::AGO::Session.new client_id: CONF[:client_id],
                                        refresh_token: CONF[:refresh_token],
                                        type: :device
    at = agos.access_token
    Timecop.travel agos.ago_data[:expires_at] do
      _at = agos.access_token
      session_should_be_ok agos
      at.should_not eq _at
    end
  end

end

describe Geotrigger::Session do

  it 'fetches an access token for client credentials' do
    s = Geotrigger::Session.new client_id: CONF[:client_id],
                                client_secret: CONF[:client_secret]
    s.access_token.should_not be nil
  end

  it 'fetches an access token for client id' do
    s = Geotrigger::Session.new client_id: CONF[:client_id],
                                type: :device
    s.access_token.should_not be nil
  end

  it 'uses a given access token' do
    s = Geotrigger::Session.new client_id: CONF[:client_id],
                                client_secret: CONF[:client_secret]
    s.access_token = 'foo'
    s.access_token.should eq 'foo'
  end

  it 'uses a given refresh token' do
    s = Geotrigger::Session.new client_id: CONF[:client_id],
                                refresh_token: CONF[:refresh_token],
                                type: :device
    s.access_token.should_not be nil
  end

  it 'knows what type it is' do
    s = Geotrigger::Session.new client_id: CONF[:client_id],
                                client_secret: CONF[:client_secret]
    s.application?.should be true
    s.device?.should be false
    s = Geotrigger::Session.new client_id: CONF[:client_id],
                                type: :device
    s.application?.should be false
    s.device?.should be true
  end

  it 'raises errors correctly' do
    s = Geotrigger::Session.new
    ->{ s.post 'application/permissions' }.should raise_error
  end

end
