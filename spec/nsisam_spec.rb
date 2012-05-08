require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe NSISam do

  before :all do
    @nsisam = NSISam::Client.new user: 'test', password: 'test',
                                 host: 'localhost', port: '8888'
    @keys = Array.new
    @fake_sam = NSISam::FakeServerManager.new.start_server
  end

  after :all do
    @fake_sam.stop_server
  end

  context "cannot connect to server" do
    it "throws error if couldn't connect to the server" do
      sam = NSISam::Client.new user: 'test', password: 'test',
                                   host: 'localhost', port: '4000'
      expect { sam.store('anything') }.to raise_error(NSISam::Errors::Client::ConnectionRefusedError)
    end
  end

  context "storing" do
    it "can store a value in SAM" do
      response = @nsisam.store("something")
      response.should_not be_nil
      response.should have_key("key")
      response.should have_key("checksum")
    end
  end

  context "deleting" do
    it "can delete a stored value" do
      @nsisam.store("delete this")["key"].should == 'value delete this stored'
      response = @nsisam.delete("delete this")
      response["deleted"].should be_true
    end

    it "raises error when key not found" do
      expect { @nsisam.delete("i dont exist") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end
  end

  context "retrieving" do
    it "can retrieve a stored value" do
      @nsisam.store("retrieve this")["key"].should == 'value retrieve this stored'
      response = @nsisam.get('retrieve this')
      response["data"].should == "data for key retrieve this"
    end

    it "can retrieve a stored value and automaticly verify its checksum" do
      @nsisam.should_receive(:verify_checksum).with('data for key retrieve this', 0).and_return(0)
      @nsisam.store("retrieve this")["key"].should == 'value retrieve this stored'
      response = @nsisam.get('retrieve this', 0)
      response["data"].should == "data for key retrieve this"
    end

    it "raises errors when expected checksum doesn't match the calculated one" do
      wrong_checksum = 333
      @nsisam.store("retrieve this")["key"].should == 'value retrieve this stored'
      expect { @nsisam.get('retrieve this', 333) }.to raise_error(NSISam::Errors::Client::ChecksumMismatchError)
    end

    it "raises error when key not found" do
      expect { @nsisam.get("i dont exist") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end
  end

  context "updating" do
    it "can update values in keys already stored" do
      @nsisam.store("update this")["key"].should == 'value update this stored'
      response = @nsisam.update('update this', "updated")
      response["key"].should == 'update this'
      response.should have_key("checksum")
    end

    it "raises error when key not found" do
      expect { @nsisam.update("dont exist ruby is fast", "foo") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end
  end

  context "get configuration" do
    before do
      NSISam::Client.configure do
        user     "why"
        password "chunky"
        host     "localhost"
        port     "8888"
      end
    end

    it "by configure" do
      sam = NSISam::Client.new
      sam.instance_variable_get(:@user).should == "why"
      sam.instance_variable_get(:@password).should == "chunky"
      sam.instance_variable_get(:@host).should == "localhost"
      sam.instance_variable_get(:@port).should == "8888"
    end

    it "by initialize parameters" do
      sam = NSISam::Client.new(user: 'luckystiff', password: 'bacon', host: 'why.com', port: '9999')
      sam.instance_variable_get(:@user).should == "luckystiff"
      sam.instance_variable_get(:@password).should == "bacon"
      sam.instance_variable_get(:@host).should == "why.com"
      sam.instance_variable_get(:@port).should == "9999"
    end
  end
end
