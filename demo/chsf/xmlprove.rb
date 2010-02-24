# XML Prove
# This is a simple XML validator or schema (not to be confused with the XML-Schema).
# It is simpler in nature then XML-Schema itself.
# But no XML-Schema validator is available for Ruby at this time.
# I don't want to write my own XML-Schema validator as REXML is said to have one in the works.
# In the mean time I will use this, my own basic validator, XML-Proof.
# Who knows, perhaps it will prove better than XML-Schema in the long run ;-)

require "rexml/document"
include REXML

class Proof_Listener

	#
	def initialize(xml_file)
	
		# input
		@xmldoc = Document.new(xml_file)
		
		# thruput
		@tags = Array.new
		@errors = Array.new
		
	end

	# listener function for when a tag element opens
	def tag_start(name, attr)
	
		@tags.push(name)
	
		attr.each do |a|
			if a[0] != 'count' and a[0] != 'trace'
				attribute(a[0], a[1])
			end
		end
	
	end
	
	# listener function for when a tag element closes
	def tag_end(name)
	
		@tags.pop
	
	end
	
	# called from tag_start to process attribute nodes
	def attribute(name, text)
		
		re = Regexp.new(text)
		xp = build_xpath(@tags) + "/@" + name
		prove_entry(re, xp)
		
	end
	
	# listener function when a text entry is processed
	def text(text)
	
		re = Regexp.new(text)
		xp = build_xpath(@tags)
		prove_entry(re, xp)
	
	end

	# this builds an xpath from the tags array
	def build_xpath(tags_array)
		
		result = ""
		
		if tags_array.empty?
			result = ""
		else
			tags_array.each do |a|
				result = result + "/" + a
			end
		end
		
		return(result)
		
	end

	# this validates entries angaint the regular expession
	def prove_entry(reg_exp, xpath)
	
		@xmldoc.elements.each(xpath) do |element|
			md = reg_exp.match(element.text)
			# error check
			if md == nil
				puts "Error at #{xpath}, '#{element.text}' =~ #{reg_exp.source}"
				@errors.push [[xpath, reg_exp.source]]
			end
			
		end
		
	end

	# this returns the xml document with editorial markups
	def editorial_markup
	
	end

	# this returns the array of error results
	def editorial_errors
		return @errors
	end

	# this returns true if the document passed validation, otherwise false
	def valid?
		if @errors.empty?
			return true
		else
			return false
		end
	end

end

# command line operation
if $0 == __FILE__

	if ARGV.length < 2
	
		puts "USAGE: #{$0} proof-sheet xml-document"
		puts "e.g. #{$0} proof.xml data.xml"
	
	else

		proof_path = ARGV[0]
		doc_path = ARGV[1]

		xml_proof = File.new(proof_path)
		xml_file = File.new(doc_path)

		# validate source file against proof
		listener = Proof_Listener.new(xml_file)
		Document.parse_stream(xml_proof, listener)

		# report
		if listener.valid?
			puts "GOOD DOCUMENT"
		else
			puts "BAD DOCUMENT"
		end
	
	end
	
end
