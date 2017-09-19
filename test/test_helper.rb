require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  setup do
    @outage_data = {}
    @performance_data = {}
  end

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
    body= performance_json(from,to)
    stub_pingdom path: performance_path(check_id,from,to), body: body
  end

  def stub_performance_error(check_id:, from:, to:)
    stub_pingdom path: performance_path(check_id,from,to), body: '', status: 401
  end

  def stub_outage(check_id:, from:, to:)
    body=outage_json(from, to)
    stub_pingdom path: "/summary.outage/#{check_id}?from=#{from}&to=#{to}", body: body
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

  def outage_json from, to
    outage_build_data(from,to).to_json
  end

  def outage_build_data from, to
    unless outage_data(from,to)
      status='up'
      collection = []
      while from<to do
        timeto=from + (status=='up' ? rand(6*3600) : rand(1000))
        collection << { status: status, timefrom: from, timeto: timeto }
        from=timeto
        status = (%w(up down) - [status]).first
      end
      @outage_data[to_key(from,to)]={ summary: { states: collection }}
    end
    outage_data(from,to)
  end

  def outage_data from, to
    @outage_data[to_key(from,to)]
  end

  def performance_json from, to
    performance_build_data(from,to).to_json
  end

  def performance_data from,to
    @performance_data[to_key(from,to)]
  end

  def performance_build_data from, to

    unless performance_data(from,to)
      hours = {}
      from.step(to,3600) { |x| hours[x]={ starttime: x, avgresponse: rand(1000), uptime: 0, downtime: 0, unmonitored: 0 }}
      outage_build_data(from,to)[:summary][:states].each do |state|
        interval = state[:timeto] - state[:timefrom]
        hours.keys.each do |h|

          if h.between?(state[:timefrom],state[:timeto])
            add_time=3600
            add_time=interval if interval<add_time
            hours[h][(state[:status]+'time').to_sym]+=add_time
            interval-=add_time
          end

        end

        @performance_data[to_key(from,to)]= { summary: { hours: hours.values }}
      end
    end

    performance_data(from,to)

  end

  def to_key(*args)
    args.join(',')
  end

end
