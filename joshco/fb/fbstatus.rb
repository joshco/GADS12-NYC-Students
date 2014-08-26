require 'koala'
require 'pry'
require 'andand'
require 'pp'

OAUTH_ACCESS_TOKEN = File.read('oauth_token.txt')

OUTPUT_TOKEN='wufm'

OBJECT="washingtonunited"

def main

  @graph = Koala::Facebook::API.new(OAUTH_ACCESS_TOKEN)

  results = @graph.get_object("#{OBJECT}/feed")


  $full_results = {}
  full_array = []

  abort = false
  counter = 0
  max_pages = 100
#:fields => "likes.summary(true)")


#binding.pry

  while results && !abort do

    puts "reading page #{counter}"
    results.each do |r|
      r['like_count_api'] = 0
      r['comment_count_api'] = 0
      r['share_count_api'] = r['shares'].nil? ? 0 : r['shares']['count']

      $full_results[r['id']] = r

    end
    batch_success=get_likes(results)


    abort = (counter >= max_pages)
    #binding.pry
    sleep 4
    begin
      results = results.next_page

    rescue Koala::Facebook::ClientError => ex
      pp ex
      if ex.fb_error_code == 613
        #sleep for a minute then retry
        puts "Sleeping 60.."
        sleep 60
        if batch_success
          puts "Retrying next set..."
          retry
        else
          puts "repeating current set"
        end

      end
    end

    counter += 1
  end

  full_array = $full_results.map { |k, v| v }; nil
  save $full_results, OUTPUT_TOKEN + '.hash.json'
  save full_array, OUTPUT_TOKEN + '.array.json'

end


def save(obj, filename)

  json = JSON.pretty_generate(obj)
  File.open(filename, 'w') { |file| file.write(json) }
end

def get_likes(results)
  success = true

  puts "batch requests..."
  puts "sleep 30"
  sleep 30
  puts "executing batch"
  batch_res = @graph.batch do |batch|
    results.each do |r|
      # only if next page
      begin
        if r['likes']['paging']['next'] != nil
          next_token=r['likes']['paging']['cursors']['after']
          batch.get_object("#{r['id']}",
                           :fields => "likes.summary(true),comments.summary(true)")
        end

      rescue
      end


    end

  end
  batch_res.each do |h|
    begin

      id=h['id']

      unless h['likes'].nil?
        like_count = h['likes']['summary']['total_count']
        $full_results[id]['like_count_api'] = like_count

      end
      unless h['comments'].nil?
        comment_count = h['comments']['summary']['total_count']
        $full_results[id]['comment_count_api'] = comment_count
      end
    rescue Exception => ex
      pp ex
      success=false
    end

  end
  return success

end

# do main
main

# results.each do |r|
# 	shares = r['shares']['count'] if r['shares']
# 	comments = r['comments']['data'].andand.count if r['comments']
# 	likes = r['likes']['data'].andand.count if r['likes']

# 	#puts "ID: #{r['id']}"
# 	puts "C: #{comments}  \tL: #{likes} \tS: #{shares}"
# end



