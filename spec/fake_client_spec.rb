require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'net/http'

describe "NSISam::FakeClient" do
  before :all do
    @nsisam = NSISam::FakeClient.new
  end

  it "can store a value" do
    response = @nsisam.store("something")
    response.should_not be_nil
    response.key.should_not be_nil
    response.checksum.should_not be_nil
  end

  it "can store a file" do
    response = @nsisam.store_file("some file not in base64", 'dumb.txt')
    response.should_not be_nil
    response.key.should_not be_nil
    response.checksum.should_not be_nil
  end

  it "can delete a stored value" do
    resp = @nsisam.store("delete this")
    response = @nsisam.delete(resp.key)
    response.should be_deleted
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
    response = @nsisam.get(resp.key)
    response.data.should == "retrieve this"
  end

  it "can retrieve a stored file" do
    resp = @nsisam.store_file("file not in base64", 'dumb.txt')
    response = @nsisam.get_file(resp.key)
    response.data.should_not be_nil
  end

  it "can update values in keys already stored" do
    resp = @nsisam.store("update this")
    response = @nsisam.update(resp.key, "updated")
    response.key.should == resp.key
    @nsisam.get(response.key).data.should == "updated"
    response.checksum.should_not be_nil
  end

  context "can host files" do
    it "stored by #store_file" do
      response = @nsisam.store_file("file not in base64", 'dumb.txt')
      response.key.should_not be_nil
      request = Net::HTTP.get_response(URI.parse("http://#{@nsisam.host}:#{@nsisam.port}/file/#{response.key}"))
      request.body.should == "file not in base64"
    end

    it "stored by #store in a dict with file and filename" do
      data = {file: Base64.encode64('a file'), filename: 'dumb.txt'}
      response = @nsisam.store(data)
      request = Net::HTTP.get_response(URI.parse(@nsisam.download_link_for_file(response.key)))
      request.body.should == "a file"
    end

    it "should update the hosted file when the file is updated through #store" do
      data = {file: Base64.encode64('a file'), filename: 'dumb.txt'}
      response = @nsisam.store(data)
      request = Net::HTTP.get_response(URI.parse(@nsisam.download_link_for_file(response.key)))
      request.body.should == "a file"

      data = {file: Base64.encode64('another file'), filename: 'dumb.txt'}
      response = @nsisam.store(data)
      request = Net::HTTP.get_response(URI.parse(@nsisam.download_link_for_file(response.key)))
      request.body.should == "another file"
    end

    it "should update the hosted file when the file is updated through #store_file" do
      response = @nsisam.store_file('a file', 'dumb.txt')
      request = Net::HTTP.get_response(URI.parse(@nsisam.download_link_for_file(response.key)))
      request.body.should == "a file"

      response = @nsisam.update_file(response.key, 'another file', 'dumb.txt')
      request = Net::HTTP.get_response(URI.parse(@nsisam.download_link_for_file(response.key)))
      request.body.should == "another file"
    end
  end

end
