require 'anemone'
require "nokogiri"
require "rubygems"
require "open-uri"
require "digest/md5"
require "net/http"
require "uri"
require 'set'
require 'date'
require 'chronic'

# stores the links to visited
links = []
t =[]
$count = 0
queue = Queue.new

# Read the csv and make list of links to visited

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
links = links.slice(0..0)


#check valid links

def check_link(url)
  if url ==  nil
     return false
  end
  str = url.to_s
  str = str.downcase
  #puts "lowercase : "+str
  #$key_words_array.clear
 #puts $key_words_array[2]
  #$key_words_array = ["meeting","minutes","board","agenda"]
   


    #puts str
  chk_valid_link = $key_words_array.find { |e|  
      #puts "----"+e
         if(str.include? e)
           #puts $key_words_array
          
           return true
         end
         
        
      
      }
 # puts "chk_valid_link :"+chk_valid_link
  #if(str =~ /[Bb]oard/ || str =~ /[Mm]eeting/ || str =~ /[Mm]inutes/ || str =~ /[Aa]genda/)
  #return true
  #end
  
  return false
end

#check if link is date

def check_date(str)
  
  if str == nil
    return false
  end
 
  isvalidDate = Chronic.parse(str)
       if(isvalidDate)
       #puts "valid date"
       return true
       else
         return false
       end
end

def strip_domain(str) 
  if str.start_with? "http"
    path = URI(str).path
    #puts "path : "+path
    return path
  end
  return str
end


# classify link text and url with given keywords

def check_url(page,url,base)
  #puts "url :"+page.depth.to_s+" "+url.to_s
  #if(page.depth.to_s == "0")
  # return true
  # else
  #return false
  #end

  str = url.to_s
  str = str.gsub(' ','%20')
  #puts "check :"+str
  #puts base
  strip = base.split("/")
  protocol = strip[0]
  domain = strip[2]
  if page.doc
    page.doc.css('a').each do |link|
      curr_href = link.attributes['href'].to_s
      #puts "curr_href  :"+curr_href
      curr_href = curr_href.gsub(' ','%20')
     
     #puts "parent :"+link.parent()
      #if curr_href.start_with? '/'
      #  curr_url = protocol + "//" + domain + curr_href
      #else 
      # curr_url = curr_href
      #end
      if curr_href.start_with? "http"
        curr_url = URI.parse(curr_href).to_s
      else 
        curr_url = URI.join(base,curr_href).to_s rescue ""
        #puts "base :"+base.to_s
        #puts "constructed :"+curr_url.to_s
=begin
            if(curr_href.start_with?"/")
            curr_url = URI.join(base,curr_href).to_s rescue ""
            else
               dummy_str = str.split("/")
               base=dummy_str[dummy_str.length - 1]
               puts "base :"+base
               curr_url = URI.join(base,curr_href).to_s rescue ""
               #puts "dummy_str :"+curr_url
            end
=end
      end
        #puts "url : "+ curr_url
       #puts "link text " + link.text
      if (str == curr_url)
        #puts "returning "+ curr_url
        #puts "link text " + link.text
        accepted = check_link(link.text) || check_link(strip_domain(curr_href)) 
        #|| check_date(link.text)
        #puts "accepted : "+ accepted.to_s
        return accepted
      end
    end
  end
  #puts "not selected..." + str
  return false

end



# crawl the links from base url upto depth = 3
puts "crawling started ...."+Time.now.to_s
start = Time.now
links.each do |l|
  Anemone.crawl(l, :depth_limit => 3) do |anemone|
  #puts "base url :"+l.to_s
   anemone.focus_crawl { |page| page.links.select{|link| check_url(page,link,page.url.to_s)  } }

    anemone.on_every_page do |page|
      puts "Every page url  :"+page.depth.to_s+"  :"+page.url.to_s
     
    

      #puts "visiting.. " + page.url.to_s
      hash = Digest::MD5.hexdigest(page.url.to_s)
      spext = page.url.to_s.split('/')
      ext = spext[spext.length-1].split('.')
      ext = ext[ext.length-1]
     # puts "ext :"+ext
      ext = ext.downcase
      
      #puts "queue ++++==: "+queue.empty?().to_s+" "+queue.length.to_s
             queue.enq(page.url)
              #puts "queue : "+queue.empty?().to_s+" "+queue.length.to_s
              if($count < 4)
                Thread.new{
                  puts "++++++++++++++++++++++++++++++++++++++++"+$count.to_s
                  $count = $count+1
                  begin
                  #response = Net::HTTP.get_response(page.url)
                  response = Net::HTTP.get_response(queue.deq())
                  if response.code == "200"
                    filename = hash
                    if ext =~ /pdf/ 
                      filename = filename + ".pdf"
                    elsif ext =~ /doc/
                      filename = filename + ".doc"           
                    else
                      filename = filename + ".html"
                    end
                    File.open("../storage/"+filename, 'w') { |f| f.write(response.body) }
                  end
                rescue Timeout::Error
                  puts "sorry the connection timedout"
          
                end
                  puts "thread ended......."
                   $count = $count - 1
               }
              end
      
  
    end
       

  end
end

puts "crawling ended ...."+(Time.now - start).to_s

