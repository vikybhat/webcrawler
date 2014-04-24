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
$child_thread = []
$count = 0
$queue = Queue.new
mutex = Mutex.new
$rejected_count = 0
$HashMap = Hash.new
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
links = links.slice(27..27)


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
    path = URI(str).path rescue ""
    #puts "path : "+path
    return path
  end
  return str
end


# classify link text and url with given keywords

$download_only =  %w(pdf doc)

def make_hashmap(page,base) 
   $HashMap = Hash.new
    if page.doc
      page.doc.css('a').each do |link| 
        curr_href = link.attributes['href'].to_s
        curr_href = curr_href.gsub(' ','%20')
        if curr_href.start_with? "http"
          curr_url = URI.parse(curr_href).to_s rescue ""
        else 
          curr_url = URI.join(base,curr_href).to_s rescue ""
        end
        accepted = check_link(link.text) || check_link(strip_domain(curr_href)) 
        if accepted
          hash = Digest::MD5.hexdigest(curr_url).to_s  
          $HashMap[hash] = link.text
        end
      end
    end
    #puts "hash map .. #{$HashMap}"
end

def check_urls(url)
    
  str = url.to_s
  str = str.gsub(' ','%20')
  #puts "links.." 
  curr_hash = Digest::MD5.hexdigest(str).to_s
  #puts "hashmap #{$HashMap}"
  accepted = $HashMap.has_key?(curr_hash)
  if(accepted)
    link_text = $HashMap[curr_hash]
    #|| check_date(link.text)
    #puts "accepted : "+ accepted.to_s
    puts "accepted ..." + str
    spext = url.to_s.split('/')
    ext = spext[spext.length-1].split('.')
    ext = ext[ext.length-1]
    # puts "ext :"+ext
    ext = ext.downcase
    if (ext =~ /pdf/ || ext =~ /doc/)
     puts "pdf .. "+ url.to_s
    $queue.enq(url)
    return false
    end
      return accepted
   end
  
  return false
   
end

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
    #puts "total links .. " + page.doc.css('a').size.to_s
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
        curr_url = URI.parse(curr_href).to_s rescue ""
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
        spext = url.to_s.split('/')
        ext = spext[spext.length-1].split('.')
        ext = ext[ext.length-1]
                      # puts "ext :"+ext
        ext = ext.downcase
        if accepted && (ext =~ /pdf/ || ext =~ /doc/)
         #puts "pdf .. "+ url.to_s
         $queue.enq(url)
         return false
        end
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

files = []
downloaded = Set.new
=begin
 t=Thread.new {
flag = true
 while flag
    #while $count < 4
    if ! $queue.empty?() 
      url = $queue.deq()
      #url = ""
      if(!downloaded.include? url.to_s)
        files.push(url.to_s)
        flag = file_download(url)
        downloaded.add(url.to_s)       
      end        
    #end
    
    end
end
}
=end

def file_download(url)
  if(url.to_s.strip != "ended")
                   
                        #return true
                        puts "downloading... " + url.to_s
                     # puts "queue length .. " + queue.length.to_s
                      hash = Digest::MD5.hexdigest(url.to_s)
                      spext = url.to_s.split('/')
                      ext = spext[spext.length-1].split('.')
                      ext = ext[ext.length-1]
                      # puts "ext :"+ext
                      ext = ext.downcase
                      #Thread.abort_on_exception = true
                     puts "create thread"
                     th = Thread.new{
                      puts "++++++++++++++++++++++++++++++++++++++++"+$count.to_s
                      
                      
                      begin
                      #response = Net::HTTP.get_response(page.url)
                      response = Net::HTTP.get_response(url)
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
                      
                      else
                        $rejected_count = $rejected_count + 1
                        puts "rejected "+$rejected_count.to_s
                      end
                    rescue Timeout::Error
                      puts "sorry the connection timedout"
              
                    end
                      puts "thread ended......."
                       #$count = $count - 1
                   }
                  $child_thread.push(th)
                  return true
              else
                  puts "break taken"
                  return false
  
               end
               $count =  $count + 1
 
end

escape_ext = %w(flv swf png jpg gif asx zip rar tar 7z gz jar js css dtd xsd ico raw mp3 mp4 wav wmv ape aac ac3 wma aiff mpg mpeg avi mov ogg mkv mka asx asf mp2 m1v m3u f4v xls ppt pps bin exe rss xml)
#t.join
links.each do |l|
  Anemone.crawl(l, :depth_limit => 3) do |anemone|
  #puts "base url :"+l.to_s
    anemone.focus_crawl { |pg| pg.links.select{|link| check_urls(link)  } }
    #anemone.focus_crawl { |pg| pg.links.select{|link| check_url(pg,link,pg.url.to_s)  } }

    anemone.on_every_page do |page|
      puts "Every page url  :"+page.depth.to_s+"  :"+page.url.to_s     
      puts "links on page : "+page.links.size.to_s
      make_hashmap(page,page.url.to_s)   
      #puts "visiting.. " + page.url.to_s
      hash = Digest::MD5.hexdigest(page.url.to_s)
      spext = page.url.to_s.split('/')
      ext = spext[spext.length-1].split('.')
      ext = ext[ext.length-1]
     # puts "ext :"+ext
      ext = ext.downcase
      
      #puts "queue ++++==: "+queue.empty?().to_s+" "+queue.length.to_s
             $queue.enq(page.url)
              #puts "queue : "+queue.empty?().to_s+" "+queue.length.to_s
=begin
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
=end      
  puts "every page End.."
    end
       

    anemone.skip_links_like /\.#{escape_ext.join('|')}$/
   

  end
end

$queue.enq("ended")
puts "crawling ended ...."+(Time.now - start).to_s
t.join
$child_thread.each do |th|
  th.join
end

files.each do |file|
  puts "download file: "+file
end   

puts "crawling ended ...."+(Time.now - start).to_s


