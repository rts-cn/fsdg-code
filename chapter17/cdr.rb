require 'sinatra'
require 'nokogiri'

post '/cdr' do
	doc  = Nokogiri::XML(request["cdr"])

	caller = doc.xpath("/cdr/variables/user_name//text()")
	dest = doc.xpath("/cdr/callflow/caller_profile/destination_number//text()")
	start_epoch = doc.xpath("/cdr/variables/start_epoch//text()")
	answer_epoch = doc.xpath("/cdr/variables/answer_epoch//text()")
	end_epoch = doc.xpath("/cdr/variables/end_epoch//text()")

	puts "caller: #{caller}"
	puts "dest: #{dest}"
	puts "start_epoch: #{start_epoch}"
	puts "answer_epoch: #{answer_epoch}"
	puts "end_epoch: #{end_epoch}"

	"CDR saved\n"
end
