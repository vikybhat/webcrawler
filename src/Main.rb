require_relative "web_crawler"
require_relative "ResourceFetcher"



links = []

File.foreach('../input/BoardMinutesLocations-100.csv').with_index { |line, line_num|
#puts "#{line_num}: #{line}"
  if line_num > 0
    link = line.split(',')[2]
    if(link != "NA")
    links.push(link)
    end
  #puts link
  end
#puts link
}

#read keywords from text file
   $key_words_array = []
   File.foreach('../input/key_words.txt') { |s|
     s = s.strip
    $key_words_array.push(s)
  }
# Taking first few links
links = links.slice(0..4)


$fetcher = ResourceFetcher.new(8,8,"../storage/")
$fetcher.start_fetching

puts "finished creating threads ..."

$crawler = WebCrawler.new($fetcher,$key_words_array)
$depth = 3
start  = Time.now
links.each do |link|
  
  $crawler.start_crawl(link,$depth)
  #puts "crawling ended ...."+(Time.now - start).to_s
end

$fetcher.end_request()

puts "crawling ended ...."+(Time.now - start).to_s



