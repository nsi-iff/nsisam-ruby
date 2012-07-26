require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "NSISam::FakeClient" do
  before :all do
    @nsisam = NSISam::FakeClient.new
  end

  it "can store a value" do
    response = @nsisam.store("something")
    response.should_not be_nil
    response.should have_key("key")
    response.should have_key("checksum")
  end

  it "can delete a stored value" do
    resp = @nsisam.store("delete this")
    response = @nsisam.delete(resp["key"])
    response["deleted"].should be_true
  end

  it "raises error when key not found" do
    expect { @nsisam.delete("i dont exist") }.to
             raise_error(NSISam::Errors::Client::KeyNotFoundError)

    expect { @nsisam.get("i dont exist") }.to
             raise_error(NSISam::Errors::Client::KeyNotFoundError)

    expect { @nsisam.update("i dont exist", "nothing") }.to
             raise_error(NSISam::Errors::Client::KeyNotFoundError)
  end

  it "can retrieve a stored value" do
    resp = @nsisam.store("retrieve this")
    response = @nsisam.get(resp['key'])
    response["data"].should == "retrieve this"
  end

  it "can update values in keys already stored" do
    resp = @nsisam.store("update this")
    response = @nsisam.update(resp['key'], "updated")
    response["key"].should == resp['key']
    @nsisam.get(response['key'])['data'].should == "updated"
    response.should have_key("checksum")
  end
end
