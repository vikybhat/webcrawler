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

class WebCrawler
  def initialize(fetcher,keywords)
    @depth = 3
    @link = nil
    #@selector =  nil
    @HashMap = nil
    @fetcher = fetcher
    @fetched = Set.new
    @keywords = keywords
    @download_only =  %w(pdf doc)
    @escape_ext = %w(flv swf png jpg gif asx zip rar tar 7z gz jar js css dtd xsd ico raw mp3 mp4 wav wmv ape aac ac3 wma aiff mpg mpeg avi mov ogg mkv mka asx asf mp2 m1v m3u f4v xls ppt pps bin exe rss xml)
  end

  def check_link(url)
    if url ==  nil
    return false
    end
    str = url.to_s
    str = str.downcase
    #puts str
    chk_valid_link = @keywords.find { |e|
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

  def strip_domain(str)
    if str.start_with? "http"
      path = URI(str).path rescue ""
    #puts "path : "+path
    return path
    end
    return str
  end

  def select_link(link_text,href)
    return check_link(link_text) || check_link(strip_domain(href))
  end

  def make_hashmap(page,base)
    @HashMap = Hash.new
    if page.doc
      page.doc.css('a').each do |link|
        curr_href = link.attributes['href'].to_s
        curr_href = curr_href.gsub(' ','%20')
        if curr_href.start_with? "http"
          curr_url = URI.parse(curr_href).to_s rescue ""
        else
          curr_url = URI.join(base,curr_href).to_s rescue ""
        end
        accepted = select_link(link.text,curr_href)
        if accepted
          hash = Digest::MD5.hexdigest(curr_url).to_s
        @HashMap[hash] = link.text
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
    accepted = @HashMap.has_key?(curr_hash)
    if(accepted)
      link_text = @HashMap[curr_hash]
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

        if !@fetched.include? url.to_s
        @fetcher.enq_request(url)
        @fetched.add(url.to_s)
        end
      return false
      end
    return accepted
    end

    return false

  end

  def start_crawl(link,depth)
    @link = link
    #@selector = selector
    @depth = depth
    @fetched  = Set.new
    Anemone.crawl(@link,:depth_limit => depth) do |anemone|
      anemone.focus_crawl { |pg| pg.links.select{|l| check_urls(l)  } }
      anemone.on_every_page do |page|
        puts "Every page url  :"+page.depth.to_s+"  :"+page.url.to_s
        puts "links on page : "+page.links.size.to_s
        make_hashmap(page,page.url.to_s)
        @fetcher.enq_request(page.url)
      end
      anemone.skip_links_like /\.#{@escape_ext.join('|')}$/
    end
  end
end