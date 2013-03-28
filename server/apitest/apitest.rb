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
  client.post(
    'http://localhost:9292/foo/api/m/newarticle',
    basicopt.merge(:content => contents.sample))
end

