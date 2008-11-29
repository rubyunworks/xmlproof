# XMLProof/Ruby - Proofsheet
# <a schema for the rest of us/>
# Copyright (c) 2002 Thomas Sawyer, Ruby License

require 'tomslib/rerexml'
require 'tomslib/communication'

include TomsLib::Communication

module XMLProof
  
	# A Proofsheet is single proofsheet of a Proof
  class Proofsheet
  
    attr_reader :url, :document
  
    def initialize(url)
      @url = url
      @document = REXML::Document.new(fetch_xml(@url))
    end
  
  end  # Proofsheet


  # Proofsheets is an array of Proofsheet objects (tied together they become a whole Proof)
  class Proofsheets < Array

    # Loads proofsheets.
		def load_proofsheets(*xps_sources)
			xps_sources.each do |url|
        # we assume this is a valid xps
        self << Proofsheet.new(url)
			end
		end
    
    # Loads an XML document's proofsheets as given by its internal schema processing instructions.
    # It subsequently returns the REXML::Document.
    # This only takes a url (or local file path).
		def load_document_proofsheets(xml_url)
      xml_document = REXML::Document.new(fetch_xml(xml_url))
      xml_document.schema_instructions.each do |si|
        uri = si.attributes['uri'].downcase
        url = si.attributes['url']
        # be sure we only get relavent schema types
        if uri.downcase == "http://www.transami.net/namespace/xmlproof"
          if is_relative?(url)
            relative_to_xml_url = File.dirname(xml_url) + '/' + url
          else
            relative_to_xml_url = url
          end
          self << Proofsheet.new(relative_to_xml_url)
        end
      end
      return xml_document
    end

  end  # Proofsheets

end  # XMLProof
