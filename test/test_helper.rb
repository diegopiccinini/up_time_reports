require File.expand_path('../../config/environment', __FILE__)
require File.expand_path('../../lib/report_builder', __FILE__)
require File.expand_path('../../lib/vpc_report_builder', __FILE__)
require File.expand_path('../../lib/global_report_builder', __FILE__)

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
      end_to=to
      end_to+= 1.day.to_i if %w(week).include?resolution
      loop do
        factor = resolution=='hour' ? 6 : 1
        timeto=timefrom + (status=='up' ? rand(factor * 1.send(resolution).to_i) : rand(1000))
        timeto=end_to if timeto>=end_to
        collection << { status: status, timefrom: timefrom, timeto: timeto }
        break if timeto==end_to
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

      end_steps = to
      end_steps+=time_period if %w(week).include?resolution

      from.step(end_steps,time_period) do |x|
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

        if total_time>0 and total_time!=time_period and h[:starttime]<to
          raise "total time #{total_time} is wrong in #{h.to_s} time period #{time_period}"
        end

      end
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

  def build_report_data report
    from =report.from.to_i
    to = report.to.to_i
    resolution= report.resolution
    outage_build_data(report.vpc.id,from,to,resolution)[:summary][:states].each do |outage|
      report.outages.create to_time( outage, [:timefrom, :timeto])
    end
    performance_build_data(report.vpc.id, from,to,resolution)[:summary][resolution.pluralize.to_sym].each do |performance|
      report.performances.create to_time(performance, [:starttime])
    end
  end

  def build_year_report_data report
    from =report.from
    1.upto(12) do |m|
      to = from.next_month
      average= { 'up' => 0 , 'down' => 0 , 'unknown' => 0 }
      outage_build_data(report.vpc.id,from.to_i,to.to_i, report.resolution)[:summary][:states].each do |outage|
        o=to_time( outage, [:timefrom, :timeto])
        average[o[:status]]+= o[:timeto].to_i - o[:timefrom].to_i
        report.outages.create o
      end
      report.averages.create from: from, to: to, avgresponse: rand(1000), totalup: average['up'] , totaldown: average['down'], totalunknown: average['unknown']
      from=to
    end
  end

  def to_time hash, keys
    hash.each_pair do |key, value|
      hash[key]= Time.at(value) if keys.include?key
    end
    hash
  end

  def by_report key
    build_report_data reports(key)
    VpcReportBuilder.new(reports(key))
  end

  def totals_asserts builder

    totals = builder.data[:totals]
    assert_kind_of Array, totals
    assert totals[builder.index('Uptime')]>0
    if builder.resolution!='week'
      assert_equal totals[builder.index('Uptime')], builder.report.outage_uptime
      assert totals[builder.index('Downtime')]>0
      assert_equal totals[builder.index('Downtime')], builder.report.outage_downtime
      assert totals[builder.index('Unknown')]>0
      assert_equal totals[builder.index('Unknown')], builder.report.outage_unknown
      assert_equal totals[builder.index('Outages')], builder.report.incidents
      assert_equal totals[builder.index('Adjusted Outages')], builder.report.adjusted_incidents
    end

    assert totals[builder.index('Uptime %')].to_f < 1.0
    assert totals[builder.index('Uptime %')].to_f > 0.4
    assert totals[builder.index('Adjusted Uptime %')].to_f >=  totals[builder.index('Uptime %')].to_f
    assert totals[builder.index('Adjusted Outages')] <=  totals[builder.index('Outages')]

  end

  def build_asserts builder, total
    builder.build
    assert_equal total, builder.data[:rows].count
    totals_asserts builder
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

