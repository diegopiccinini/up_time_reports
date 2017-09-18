require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def fixtures_json name
    file =File.join('test','fixtures','files',name)
    if file.end_with?('.erb')
      erb=ERB.new(File.read(file))
      erb.result
    else
      File.read(file)
    end
  end

  def stub_checks
    body=fixtures_json('checks.json')
    stub_pingdom path: '/checks', body: body
  end

  def stub_servertime
    body=fixtures_json('servertime.json.erb')
    stub_pingdom path: '/servertime', body: body
  end

  def stub_performance(check_id:,from:,to:)
    body=fixtures_json('performance.json.erb') if body.nil?
    stub_pingdom path: performance_path(check_id,from,to), body: body
  end

  def stub_performance_error(check_id:, from:, to:)
    stub_pingdom path: performance_path(check_id,from,to), body: '', status: 401
  end

  def stub_pingdom( path:, body: , status: 200)
    stub_request(:get, "https://api.pingdom.com/api/2.0#{path}").
      with(headers: {
      'Accept'=>'*/*',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'App-Key'=>ENV['PINGDOM_KEY'],
      'Content-Type'=>'application/json',
      'User-Agent'=>'Faraday v0.13.1'},
      basic_auth: [ENV['PINGDOM_USERNAME'], ENV['PINGDOM_PASSWORD']] ).
    to_return(status: status, body: body, headers: {})
  end

  private

  def performance_path check_id, from, to
    "/summary.performance/#{check_id}?from=#{from}&includeuptime=true&to=#{to}"
  end

end
