# XMLProof/Ruby - Proof Tool for the Command Line
# <a schema for the rest of us/>
# Copyright (c) 2002 Thomas Sayer, Ruby License
#
# This is a command line tool for XMLProver's Proofreader

require 'xmltoolkit/xmlproof/about'
require 'xmltoolkit/xmlproof/proofreader'


if $0 == __FILE__

	validargs = true
  
  case ARGV.length
  when 0
		validargs = false
	when 1
    validargs = true
    xml = ARGV[0]
    xps = nil
  else
    validargs = true
    xml = ARGV[0]
    xps = ARGV[1..-1]
  end

	
	if not validargs

    puts
    puts "#{XMLProof::Package} - Proof Tool"
		puts 
		puts "USAGE: #{$0} xml-document [proofsheet1 proofsheet2 ...]"
		puts
		puts "  e.g. #{$0} example.xml"
		puts "  -or- #{$0} example.xml example.xps"
    puts
	
  else

    if xps
      
      # create proof
      proof = XMLProof::Proof.new(*xps)
      
      # validate
      proofreader = XMLProof::Proofreader.new(proof)
      valid = proofreader.proofread_document(xml)
      
      # return results
      if valid
        puts "GOOD DOCUMENT"
      else
        puts "BAD DOCUMENT"
        prover.errors.each do |e|
          puts "namespace->#{e[0]} \t xpath->#{e[1]} \t error->#{e[2]}"
        end
      end
    
    else
    
      # validate against internal schema instructions
      proofreader = XMLProof::Proofreader.new
      valid = proofreader.proofread_document_internal(xml)
      
      # return results
      if valid
        puts "GOOD DOCUMENT"
      else
        puts "BAD DOCUMENT"
        proofreader.errors.each do |e|
          puts "namespace->#{e[0]} \t xpath->#{e[1]} \t error->#{e[2]}"
        end
      end
      
    end
    
	end
	
end

