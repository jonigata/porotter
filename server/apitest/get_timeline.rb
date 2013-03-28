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

result = JSON.parse(client.get_content(
    'http://localhost:9292/foo/api/v/timeline',
    basicopt.merge(:timeline => 1, :newest_version => 0, :count => 1)))

puts JSON.pretty_generate(result)

last_score = result['lastScore']

result = JSON.parse(client.get_content(
    'http://localhost:9292/foo/api/v/timeline',
    basicopt.merge(:timeline => 1, :newest_version => last_score, :count => 1)))

puts JSON.pretty_generate(result)

