require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures [:reports, :vpcs]

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
    stub_outage(check_id: check_id, from: from, to: to)
    body= performance_json(check_id,from,to)
    stub_pingdom path: performance_path(check_id,from,to), body: body
  end

  def stub_performance_error(check_id:, from:, to:)
    stub_pingdom path: performance_path(check_id,from,to), body: '', status: 401
  end

  def stub_outage(check_id:, from:, to:)
    body=outage_json(check_id,from, to)
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

  def performance_path check_id, from, to
    "/summary.performance/#{check_id}?from=#{from}&includeuptime=true&to=#{to}"
  end

  def outage_json check_id,from, to
    outage_build_data(check_id,from,to).to_json
  end

  def outage_build_data check_id,from, to

    unless outage_data(check_id,from,to)
      status='up'
      collection = []
      timefrom=from
      loop do
        timeto=timefrom + (status=='up' ? rand(6 * 3600) : rand(1000))
        timeto=to if timeto>=to
        collection << { status: status, timefrom: timefrom, timeto: timeto }
        break if timeto==to
        timefrom=timeto
        status = (%w(up down unknown) - [status]).shuffle.first
      end
      GlobalSetting.create name: to_key('outage_data',check_id,from,to), data: { summary: { states: collection }}.to_json
    end
    outage_data(check_id,from,to)
  end

  def outage_data check_id,from, to
    GlobalSetting.get to_key('outage_data',check_id,from,to)
  end

  def performance_json check_id,from, to
    performance_build_data(check_id,from,to).to_json
  end

  def performance_data check_id,from,to
    GlobalSetting.get to_key('performance_data',check_id,from,to)
  end

  def performance_build_data check_id,from, to

    unless performance_data(check_id,from,to)
      hours = {}
      from.step(to - 3600,3600) { |x| hours[x]={ starttime: x, avgresponse: rand(1000), uptime: 0, downtime: 0, unmonitored: 0 }}

      data=outage_data(check_id,from,to)[:summary][:states]

      hours.keys.each do |h|
        next_h = h + 3600

        # outages inside peridod
        inside_filter = data.select { |x| x[:timefrom]<next_h and x[:timeto]>h }
        inside_filter.each do |state|
          interval = [state[:timeto],next_h].min - [state[:timefrom],h].max
          hours[h][status_map[state[:status].to_sym]]+=interval
        end

      end
      hours.values.each do |h|
        total_time =h[:uptime] + h[:downtime] + h[:unmonitored]
        raise "total time #{total_time} is wrong in #{h[:strattime]}" unless total_time==3600
      end
      check_generated(data, hours)
      GlobalSetting.create name: to_key('performance_data',check_id,from,to), data: { summary: { hours: hours.values }}.to_json
    end

    performance_data(check_id,from,to)

  end

  def util_capture(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  private

  def to_key(*args)
    args.join(',')
  end

  def check_generated(data,hours)
    check(data,hours,:up)
    check(data,hours,:down)
    check(data,hours,:unknown)
  end

  def check(data,hours,status)
    key=status_map[status]
    origin=data.select { |x| x[:status]==status.to_s }.sum { |x| x[:timeto] - x[:timefrom] }
    generated=hours.values.sum { |x| x[key] }
    raise "origin #{key.to_s} #{origin} no match with #{generated}" unless origin==generated
  end

  def status_map
    { up: :uptime, down: :downtime, unknown: :unmonitored }
  end

end

