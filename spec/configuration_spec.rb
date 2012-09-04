require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "NSISam::Client::Configuration" do
  Configuration = NSISam::Client::Configuration

  it "set and return user" do
    Configuration.user 'why'
    Configuration.user.should == 'why'
  end

  it "set and return password" do
    Configuration.password 'admin123'
    Configuration.password.should == 'admin123'
  end

  it "set and return host" do
    Configuration.host '192.168.0.100'
    Configuration.host.should == '192.168.0.100'
  end

  it "set and return port" do
    Configuration.port '8888'
    Configuration.port.should == '8888'
  end

  it "set and return default expire time" do
    Configuration.expire 5
    Configuration.expire.should == 5
  end

  it "return a hash of attributes" do
    Configuration.instance_eval do
      user     "why"
      password "chunky"
      host     "localhost"
      port     "8888"
      expire   8
    end
    Configuration.settings.should == {user: "why", password: "chunky",
                                      host: "localhost", port: "8888",
                                      expire: 8}
  end
end
