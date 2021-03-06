require 'httpclient'
require 'json'

def basicopt
  {
    :api_key => open("#{File.dirname(__FILE__)}/../API_KEY").read,
    :username => 'apiman',
    :password => 'apiman',
  }
end

client = HTTPClient.new

result = JSON.parse(client.get_content(
    'http://localhost:9292/foo/api/v/timeline',
    basicopt.merge(:timeline => 1, :count => 1)))

puts JSON.pretty_generate(result)

last_score = result['oldestScore']

result = JSON.parse(client.get_content(
    'http://localhost:9292/foo/api/v/timeline',
    basicopt.merge(:timeline => 1, :newest_score => last_score, :count => 1)))

puts JSON.pretty_generate(result)
