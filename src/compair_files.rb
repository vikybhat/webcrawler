require "digest/md5"
require "set"

visited1 = Set.new
visited2 = Set.new 

=begin
 
=end

puts "reading files"

File.foreach('../src/threadoutput1.txt').with_index { |line, line_num|
  #hash = Digest::MD5(line)
  #puts line
  #puts "included .. " +line_num.to_s+"  :"+ line
  visited1.add(line)
}
$count = 0
File.foreach('../src/threadoutput.txt').with_index { |line, line_num|
  #puts line 
  if visited1.include? line
    puts "included .. " +line_num.to_s+"  :"+ line
    if visited2.include? line
      puts "repeated .." + line
    else  
      puts "new line ... " + line
      $count = $count+1
    end
  end
  
  visited2.add(line)
  
}


puts "total lines .." + $count.to_s

