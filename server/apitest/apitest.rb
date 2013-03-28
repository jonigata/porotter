require 'open-uri'

open('http://localhost:9292/foo/api/v/timeline?api_key=fd5b07f860cad77d88d2007fa103c0a7&username=apiman&password=apiman&timeline=1&level=0') do |f|
  puts f.read  
end
