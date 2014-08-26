require 'json'
require 'faraday'

filename='wufm.array.json'
dstk_baseurl='http://ec2-54-90-80-79.compute-1.amazonaws.com/'


# load json file
json = File.read(filename)

feed = JSON.parse(json)

conn = Faraday.new(:url => dstk_baseurl) do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
#  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  :net_http  # make requests with Net::HTTP
end
counter =0

feed.each do |f|

  response = conn.post do |req|
    req.url '/text2sentiment'
    req.body = f['message']
  end
  score = JSON.parse(response.body)['score']
  puts "#{f['like_count_api']} \t#{f['share_count']} \t#{score}"


  break if counter > 50
  counter += 1

end
	
