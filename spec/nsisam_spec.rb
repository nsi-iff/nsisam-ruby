require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'base64'

describe NSISam do
  before :all do
    fake_options = { user: 'test', password: 'test', host: 'localhost',
      port: '7888' }
    @options = integration_options || fake_options
    @nsisam = NSISam::Client.new(@options)
    @keys = Array.new
    @fake_sam = NSISam::FakeServerManager.new.start_server(7888) unless integrating?
  end

  before :each do
    @nsisam.expire = false
  end

  after :all do
    @fake_sam.stop_server unless integrating?
  end

  let(:file_content) { example_file_content }
  let(:filename) { 'teste.txt' }

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
      response.should respond_to("key")
      response.should respond_to("checksum")
    end

    it "can store a value with an expire time" do
      @nsisam.expire = 2
      response = @nsisam.store('teste')
      sleep(3)
      expect { @nsisam.get(response.key) }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
      @nsisam.expire = false
    end

    context "file" do
      it "encodes content before storing" do
        Base64.should_receive(:encode64).with(file_content).
          and_return(:dummy_value)
        @nsisam.should_receive(:store).with(file: :dummy_value, filename: filename).
          and_return(:dummy_result)
        @nsisam.store_file(file_content, filename).should == :dummy_result
      end
    end
  end

  context "deleting" do
    it "can delete a stored value" do
      key = @nsisam.store("delete this").key
      response = @nsisam.delete(key)
      response.should be_deleted
    end

    it "raises error when key not found" do
      expect { @nsisam.delete("i dont exist") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end
  end

  context "retrieving" do
    it "can retrieve a stored value" do
      key = @nsisam.store("retrieve this").key
      response = @nsisam.get(key)
      response.data.should == "retrieve this"
    end

    it "can retrieve a stored value and automaticly verify its checksum" do
      @nsisam.should_receive(:verify_checksum).with('retrieve this', 0).and_return(0)
      key = @nsisam.store("retrieve this").key
      response = @nsisam.get(key, 0)
      response.data.should == "retrieve this"
    end

    it "raises errors when expected checksum doesn't match the calculated one" do
      wrong_checksum = 333
      key = @nsisam.store("retrieve this").key
      expect { @nsisam.get(key, 333) }.to raise_error(NSISam::Errors::Client::ChecksumMismatchError)
    end

    it "raises error when key not found" do
      expect { @nsisam.get("i dont exist") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end

    context 'file' do
      it 'decodes content after retrieving' do
        @nsisam.should_receive(:get).with(:key, nil).
          and_return(stub(key: 'key', checksum: 999,
                          data: { 'file' => :dummy_value }, deleted?: true))
        Base64.should_receive(:decode64).with(:dummy_value).
          and_return(:decoded_dummy)
        response = @nsisam.get_file(:key)
        response.file.should == :decoded_dummy
      end

      it "can generate a direct link to download any file" do
        link = @nsisam.download_link_for_file('some_key')
        link.should == "http://#{@options[:host]}:#{@options[:port]}/file/some_key"
      end
    end
  end

  context "updating" do
    it "can update values in keys already stored" do
      key = @nsisam.store("update this").key
      response = @nsisam.update(key, "updated")
      response.key.should == key
      response.checksum.should_not be_nil
      @nsisam.get(key).data.should == 'updated'
    end

    it "can update values with an expire time to the new value" do
      response = @nsisam.store('test')
      @nsisam.expire = 2
      @nsisam.update(response.key, 'test 2')
      sleep(3)
      expect { @nsisam.get(response.key) }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end

    it "raises error when key not found" do
      expect { @nsisam.update("dont exist ruby is fast", "foo") }.to raise_error(NSISam::Errors::Client::KeyNotFoundError)
    end

    context 'file' do
      it 'encodes content before updating' do
        key = @nsisam.store_file(file_content, filename).key
        Base64.should_receive(:encode64).with(:dummy_content).
          and_return(:dummy_content)
        @nsisam.should_receive(:update).with(key, file: :dummy_content, filename: filename).
          and_return(:dummy_result)
        @nsisam.update_file(key, :dummy_content, filename).should == :dummy_result
      end
    end
  end

  context 'file storage without mocking' do
    it 'stores, retrieves and updates files' do
      updated_file_content = file_content + 'anything ha!'
      key = @nsisam.store_file(file_content, filename).key
      @nsisam.get_file(key).file.should == file_content
      @nsisam.update_file(key, updated_file_content, filename)
      @nsisam.get_file(key).file.should == updated_file_content
    end

    it 'stores, retrieves and updates documents for other nsi-services' do
      updated_file_content = file_content + 'anything ha!'
      key = @nsisam.store_file(file_content, filename, :doc).key
      @nsisam.get_file(key, :doc).file.should == file_content
      @nsisam.update_file(key, :doc, updated_file_content, filename)
      @nsisam.get_file(key, :doc).file.should == updated_file_content
    end

    it 'stores, retrieves and updates videos for other nsi-services' do
      updated_file_content = file_content + 'anything ha!'
      key = @nsisam.store_file(file_content, filename, :video).key
      @nsisam.get_file(key, :video).file.should == file_content
      @nsisam.update_file(key, :video, updated_file_content, filename)
      @nsisam.get_file(key, :video).file.should == updated_file_content
    end
  end

  context "get configuration" do
    before do
      NSISam::Client.configure do
        user     "why"
        password "chunky"
        host     "localhost"
        port     "8888"
        expire   false
      end
    end

    it "by configure" do
      sam = NSISam::Client.new
      sam.instance_variable_get(:@user).should == "why"
      sam.instance_variable_get(:@password).should == "chunky"
      sam.instance_variable_get(:@host).should == "localhost"
      sam.instance_variable_get(:@port).should == "8888"
      sam.instance_variable_get(:@expire).should == false
    end

    it "by initialize parameters" do
      sam = NSISam::Client.new(user: 'luckystiff', password: 'bacon', host: 'why.com', port: '9999', expire: 5)
      sam.instance_variable_get(:@user).should == "luckystiff"
      sam.instance_variable_get(:@password).should == "bacon"
      sam.instance_variable_get(:@host).should == "why.com"
      sam.instance_variable_get(:@port).should == "9999"
      sam.instance_variable_get(:@expire).should == 5
    end
  end
end
