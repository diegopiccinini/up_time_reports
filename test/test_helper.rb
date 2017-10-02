require File.expand_path('../../config/environment', __FILE__)
require File.expand_path('../../lib/vpc_report_builder', __FILE__)
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

  def stub_performance(check_id:,from:,to:, resolution: 'hour')
    stub_outage(check_id: check_id, from: from, to: to, resolution: resolution)
    body= performance_json(check_id,from,to,resolution)
    stub_pingdom path: performance_path(check_id,from,to,resolution), body: body
  end

  def stub_performance_error(check_id:, from:, to:, resolution: 'hour')
    stub_pingdom path: performance_path(check_id,from,to,resolution), body: '', status: 401
  end

  def stub_outage(check_id:, from:, to:, resolution: 'hour')
    body=outage_json(check_id,from, to,resolution)
    stub_pingdom path: "/summary.outage/#{check_id}?from=#{from}&to=#{to}", body: body
  end

  def stub_average(check_id:, from:, to:, resolution: 'month')
    average_build_data(check_id,from,to,resolution)
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

  def performance_path check_id, from, to, resolution='hour'
    "/summary.performance/#{check_id}?from=#{from}&includeuptime=true&resolution=#{resolution}&to=#{to}"
  end

  def outage_json check_id,from, to,resolution='hour'
    outage_build_data(check_id,from,to,resolution).to_json
  end

  def outage_build_data check_id,from, to, resolution='hour'

    unless outage_data(check_id,from,to,resolution)
      status='up'
      collection = []
      timefrom=from
      loop do
        timeto=timefrom + (status=='up' ? rand(6 * 1.send(resolution).to_i) : rand(1000))
        timeto=to if timeto>=to
        collection << { status: status, timefrom: timefrom, timeto: timeto }
        break if timeto==to
        timefrom=timeto
        status = (%w(up down unknown) - [status]).shuffle.first
      end
      GlobalSetting.create name: to_key('outage_data',check_id,from,to,resolution), data: { summary: { states: collection }}.to_json
    end
    outage_data(check_id,from,to,resolution)
  end

  def outage_data check_id,from, to, resolution='hour'
    GlobalSetting.get to_key('outage_data',check_id,from,to,resolution)
  end

  def average_build_data check_id,from,to,resolution='month'

    unless average_data(check_id,from,to,resolution)
      starting_at=Time.at(from).in_time_zone('UTC')

      1.upto(12) do
        m=starting_at.to_i
        end_at=starting_at.next_month.at_beginning_of_month
        next_month=end_at.to_i

        responsetime={ from: m, to: next_month, avgresponse: rand(1000)}
        status= { totalup: 0, totaldown: 0, totalunknown: 0 }

        stub_outage(check_id: check_id, from: m, to: next_month, resolution: resolution)

        data=outage_data(check_id,m,next_month,resolution)[:summary][:states]

        # outages inside peridod
        inside_filter = data.select { |x| x[:timefrom] < next_month and x[:timeto]>m }
        inside_filter.each do |state|
          interval = [state[:timeto],next_month].min - [state[:timefrom],m].max
          status[ ('total' + state[:status]).to_sym ]+=interval
        end

        json_data = { summary: { responsetime: responsetime, status: status }  }.to_json

        GlobalSetting.create name: to_key('average_data',check_id,m,next_month,resolution), data: json_data

        stub_pingdom path: "/summary.average/#{check_id}?from=#{m}&to=#{next_month}&includeuptime=true", body: json_data

        starting_at = end_at

      end
    end
  end

  def average_data check_id,from,to,resolution='month'
    GlobalSetting.get to_key('average_data',check_id,from,to,resolution)
  end

  def performance_json check_id,from,to,resolution='hour'
    performance_build_data(check_id,from,to,resolution).to_json
  end

  def performance_data check_id,from,to,resolution='hour'
    GlobalSetting.get to_key('performance_data',check_id,from,to,resolution)
  end

  def performance_build_data check_id,from,to,resolution='hour'

    unless performance_data(check_id,from,to,resolution)
      units = {}
      time_period = 1.send(resolution).to_i

      from.step(to - time_period,time_period) do |x|
        units[x]={ starttime: x, avgresponse: rand(1000), uptime: 0, downtime: 0, unmonitored: 0 }
      end

      data=outage_data(check_id,from,to,resolution)[:summary][:states]

      units.keys.each do |h|
        next_h = h + time_period

        # outages inside peridod
        inside_filter = data.select { |x| x[:timefrom]<next_h and x[:timeto]>h }
        inside_filter.each do |state|
          interval = [state[:timeto],next_h].min - [state[:timefrom],h].max
          units[h][status_map[state[:status].to_sym]]+=interval
        end

      end
      units.values.each do |h|
        total_time =h[:uptime] + h[:downtime] + h[:unmonitored]
        raise "total time #{total_time} is wrong in #{h[:strattime]}" unless total_time==time_period
      end
      check_generated(data, units)
      json_data = { summary: { resolution.pluralize.to_sym => units.values }}.to_json
      GlobalSetting.create name: to_key('performance_data',check_id,from,to,resolution), data: json_data
    end

    performance_data(check_id,from,to,resolution)

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

  def check_generated(data,units)
    check(data,units,:up)
    check(data,units,:down)
    check(data,units,:unknown)
  end

  def check(data,units,status)
    key=status_map[status]
    origin=data.select { |x| x[:status]==status.to_s }.sum { |x| x[:timeto] - x[:timefrom] }
    generated=units.values.sum { |x| x[key] }
    raise "origin #{key.to_s} #{origin} no match with #{generated}" unless origin==generated
  end

  def status_map
    { up: :uptime, down: :downtime, unknown: :unmonitored }
  end

end

