require 'httpclient'

def basicopt
  {
    :api_key => 'fd5b07f860cad77d88d2007fa103c0a7',
    :username => 'apiman',
    :password => 'apiman',
  }
end

client = HTTPClient.new

contents = IO.readlines("#{File.dirname(__FILE__)}/data.txt")

3.times do
  post_id = client.post_content(
    'http://localhost:9292/foo/api/m/newarticle',
    basicopt.merge(:content => contents.sample))
  rand(3).times do
    client.post_content(
      'http://localhost:9292/foo/api/m/newcomment',
      basicopt.merge(:content => contents.sample, :parent => post_id))    
  end
end

