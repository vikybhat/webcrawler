require "net/http"
require "open-uri"
require "rubygems"



class ResourceFetcher
  
  
  
  def initialize(no_of_threads,max_threads,path)
    @max_threads = max_threads
    @no_of_threads = no_of_threads
    @queue = Queue.new 
    @path = path
    #@sentinel = sentinel
    @sentinel = "$"
    @thread_pool = []
    @downloaded = Set.new
  end
  
  def enq_request(url)
    @queue.enq(url)
  end
  
  def end_request()
    enq_request(@sentinel)
    @thread_pool.each do |th|
      th.join
    end
    puts "closing resource fetchers ......"
  end
  
  def download_file(url)
     hash = Digest::MD5.hexdigest(url.to_s)
     spext = url.to_s.split('/')
     ext = spext[spext.length-1].split('.')
     ext = ext[ext.length-1]
     # puts "ext :"+ext
     ext = ext.downcase
                    

      puts "downloading ..... " + url.to_s
      
      begin
        response = Net::HTTP.get_response(url)
        
        if response.code == "200"
          puts "got response..."
          filename = hash
        if ext =~ /pdf/
          filename = filename + ".pdf"
        elsif ext =~ /doc/
          filename = filename + ".doc"
        else
          filename = filename + ".html"
        end
        File.open(@path+filename, 'w') { |f| f.write(response.body) }

        else
          puts "rejected ......"
        end
      rescue Timeout::Error
        puts "sorry the connection timedout"
      end
       puts "finished download.... "+url.to_s
       

  end
  
  def create_thread()
    th = Thread.new {
      flag = true
      while flag
        url = @queue.deq
        if(url.to_s != @sentinel)
            download_file(url)
        else
          @queue.enq(@sentinel)
          flag = false
          puts "thread is dead...."
        end
        
      end
      
    }
    
    @thread_pool.push(th)
    
  end
  
  def start_fetching()
    i = 0;
    while i < @no_of_threads do
      #create_thread();
      i = i+1
    end
  end
  
end