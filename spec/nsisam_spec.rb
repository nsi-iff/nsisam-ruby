require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe NSISam do

  before :all do
    @nsisam = NSISam::Client.new 'http://test:test@localhost:8888'
    @keys = Array.new
    @fake_sam = NSISam::FakeServer.new.start
  end

  after :all do
    @keys.each { |key| @nsisam.delete(key) }
    @fake_sam.stop
  end

  context "storing" do
    it "can store a value in SAM" do
      response = @nsisam.store("something")
      response.should_not be_nil
      response.should have_key("key")
      response.should have_key("checksum")

      @keys.push(response["key"])
    end
  end

  context "deleting" do
    it "can delete a stored value" do
      key = @nsisam.store("delete this")["key"]
      response = @nsisam.delete(key)
      response["deleted"].should be_true
    end

    it "raises error when key not found" do
      expect { @nsisam.delete("i dont exist") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end
  end

  context "retrieving" do
    it "can retrieve a stored value" do
      key = @nsisam.store("retrieve this")["key"]
      response = @nsisam.get(key)
      response["data"].should == "retrieve this"

      @keys.push(key)
    end

    it "raises error when key not found" do
      expect { @nsisam.get("non existing key") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end
  end

  context "updating" do
    it "can update values in keys already stored" do
      key = @nsisam.store("update this")["key"]
      response = @nsisam.update(key, "updated")
      response["key"].should == key
      response.should have_key("checksum")

      @keys.push(key)
    end

    it "raises error when key not found" do
      expect { @nsisam.update("ruby is fast", "foo") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end
  end

end
