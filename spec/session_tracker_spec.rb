require 'session_tracker'

describe SessionTracker, "track" do
  
  let(:redis) { mock.as_null_object }

  it "should store the user in a set for the current minute" do
    time = Time.parse("2012-05-23 15:04")
    redis.should_receive(:sadd).with("active_customer_sessions_minute_201205231504", "abc123")
    tracker = SessionTracker.new("customer", redis)
    tracker.track("abc123", time)
  end

  it "should expire the set within an hour if there is no expiry_time passed in the constructor" do
    time = Time.parse("2012-05-23 15:59")
    redis.should_receive(:expire).with("active_customer_sessions_minute_201205231559", 60 * 59)
    tracker = SessionTracker.new("customer", redis)
    tracker.track("abc123", time)
  end

  it "should expire the set within the expiry_time if there is one passed in the constructor" do
    time = Time.parse("2012-05-23 15:59")
    redis.should_receive(:expire).with("active_customer_sessions_minute_201205231559", 365*24*60*60 - 60)
    tracker = SessionTracker.new("customer", redis, 365*24*60*60)
    tracker.track("abc123", time)
  end

  it "should be able to track different types of sessions" do
    time = Time.parse("2012-05-23 15:04")
    redis.should_receive(:sadd).with("active_employee_sessions_minute_201205231504", "abc456")
    tracker = SessionTracker.new("employee", redis)
    tracker.track("abc456", time)
  end

  it "should do nothing if the session id is nil" do
    redis.should_not_receive(:sadd)
    redis.should_not_receive(:expire)
    tracker = SessionTracker.new("employee", redis)
    tracker.track(nil)
  end

  it "should not raise any errors" do
    redis.should_receive(:expire).and_raise('fail')
    tracker = SessionTracker.new("customer", redis)
    tracker.track("abc123", Time.now)
  end

end

describe SessionTracker, "active_users" do

  let(:redis) { mock.as_null_object }

  it "should do a union on the specified timespan to get a active user count" do
    time = Time.parse("2012-05-23 13:09")
    redis.should_receive(:sunion).with("active_customer_sessions_minute_201205231309",
                                       "active_customer_sessions_minute_201205231308",
                                       "active_customer_sessions_minute_201205231307").
                                       and_return([ mock, mock ])

    SessionTracker.new("customer", redis).active_users(3, time).should == 2
  end

  it "should use a default time span of 5 minutes" do
    redis.should_receive(:sunion).with(anything, anything, anything,
                                       anything, anything).and_return([ mock, mock ])

    SessionTracker.new("customer", redis).active_users.should == 2
  end

  it "should be possible to access the data" do
    redis.should_receive(:sunion).and_return([ :d1, :d2 ])
    SessionTracker.new("customer", redis).active_users_data(3, Time.now).should == [ :d1, :d2 ]
  end

end
