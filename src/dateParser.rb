require 'chronic'

 isvalidDate = Chronic.parse('Apr. 10, 2014')
  #isvalidDate = Chronic.parse('2010-4-10')
 #isvalidDate = Chronic.parse('feb14, 2004')
 if(isvalidDate)
 puts ""+isvalidDate.to_s
 else
   puts "not valid date"
 end
 
 key_words_array = []
 File.foreach('../input/key_words.txt') { |s|
  key_words_array.push(s)
}

puts key_words_array
 
