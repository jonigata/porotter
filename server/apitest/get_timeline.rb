require 'httpclient'
require 'json'

def basicopt
  {
    :api_key => 'fd5b07f860cad77d88d2007fa103c0a7',
    :username => 'apiman',
    :password => 'apiman',
  }
end

client = HTTPClient.new

puts JSON.pretty_generate(JSON.parse(client.get_content(
  'http://localhost:9292/foo/api/v/timeline',
  basicopt.merge(:timeline => 1, :level => 0))))

