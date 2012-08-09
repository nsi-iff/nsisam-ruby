require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe NSISam::Response do
  let(:response) do
    response = NSISam::Response.new('key' => 'key value',
                                    'checksum' => 'checksum value',
                                    'data' => 'data value',
                                    'deleted' => true)
  end

  it 'retrieves response data as methods' do
    response.key.should == 'key value'
    response.checksum.should == 'checksum value'
    response.data.should == 'data value'
  end

  it 'retrieves deleted as boolean method' do
    response.should be_deleted
    NSISam::Response.new('deleted' => false).should_not be_deleted
  end
end
