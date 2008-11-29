# XMLProof/Ruby - Proof
# <a schema for the rest of us/>
# Copyright (c)2002 Thomas Sawyer, Ruby License

require 'xmltoolkit/rerexml/rerexml'
require 'xmltoolkit/xmlproof/die'
require 'xmltoolkit/xmlproof/proofsheet'

module XMLProof

  # A whole Proof created by parsing a Proofsheets object
	class Proof

		attr_reader :proofsheets, :absolute_dies, :arbitrary_dies, :options, :collections
	
    # Loads and parses proofsheet schema.
		def initialize(proofsheets)
			
      if proofsheets.is_a?(Proofsheets)
        @proofsheets = proofsheets
      else
        @proofsheets = Proofsheets.new
        @proofsheets.load_proofsheets(proofsheets)
      end
      
      @absolute_dies = {}   # absolute_dies[xpath] = die
      @arbitrary_dies = {}  # arbitrary_dies[namespace, xpath] = die
      
      @options = Hash.new([])     # options[option] = [ [namespace, xpath], ... ]
      @collections = Hash.new([]) # collections[collection] = [ [ namespace, xpath ], ... ]
  
      parse_proofsheet
		end
    
    # Returns the absolute die given the namespace and xpath.
    def die(namespace, xpath)
      return @absolute_dies[[namespace, xpath]]
    end
    

		private  # --------------------------------------------

  	# parses the proofsheets to create a parsed proofsheet
    def parse_proofsheet
   
      @proofsheets.each do |proofsheet|
      
        xps_document = proofsheet.document

        # load all casted general elements
        REXML::XPath.each(xps_document.root,'descendant::*') do |element|
          namespace = element.inherited_namespace
          # absolute dies
          if namespace != "http://www.transami.net/namespace/xmlproof" and namespace != "http://transami.net/namespace/xmlproof"
            if element.has_text?
              if not element.text.strip.empty?
                xpath = element.absolute_xpath(true)
                cast = " " + element.text.strip + " "
                @absolute_dies[[namespace, xpath]] = Die.new(cast, element) if not @absolute_dies.has_key?([namespace, xpath])
              end
            end
          end
        end

        # load all casted general attributes
        REXML::XPath.each(xps_document.root,'descendant::*[@]') do |element|
          element.attributes.each_attribute do |attribute|
            prefix = attribute.inherited_prefix
            name = attribute.name
            namespace = attribute.inherited_namespace
            if namespace != "http://www.w3.org/2000/xmlns/" and prefix != 'xmlns' and name != 'xmlns'
              if namespace != "http://www.transami.net/namespace/xmlproof" and namespace != "http://transami.net/namespace/xmlproof"
                if not attribute.value.strip.empty?
                  xpath = attribute.absolute_xpath(true)        
                  cast = " " + attribute.value.strip + " "
                  @absolute_dies[[namespace, xpath]] = Die.new(cast, attribute) if not @absolute_dies.has_key?([namespace, xpath])
                end
              end
            end
          end
        end
        
        # load all casted arbitrary dies
        REXML::XPath.each(xps_document.root,'descendant::x:arbitrary', {'x' => 'http://www.transami.net/namespace/xmlproof'}) do |element|
          if element.has_text?
            if not element.text.strip.empty?
              # get xpath
              if element.attributes.has_key?('xpath')
                xpath = element.attributes['xpath']
              else
                raise "no xpath attribute given for arbitrary"
              end
              cast = " " + element.text.strip + " "
              @arbitrary_dies[xpath] = Die.new(cast, xpath) if not @arbitrary_dies.has_key?(xpath)
            end
          end
        end
  
        # link dies
        defined_dies = @absolute_dies.select { |key, die| die.link? == false } | @arbitrary_dies.select { |key, die| die.link? == false }
        defined_dies_lookup = {}
        defined_dies.each do |key, die|
          defined_dies_lookup[die.name] = die
        end
        undefined_absolute_dies = @absolute_dies.select { |key, die| die.link? == true }
        undefined_absolute_dies.each do |key, die|
          if defined_dies_lookup.has_key?(die.name)
            @absolute_dies[key].link(defined_dies_lookup[die.name])
          end
        end
        undefined_arbitrary_dies = @arbitrary_dies.select { |key, die| die.link? == true }
        undefined_arbitrary_dies.each do |key, die|
          if defined_dies_lookup.has_key?(die.name)
            @arbitrary_dies[key].link(defined_dies_lookup[die.name])
          end
        end
  
        # load options and collections
        @absolute_dies.each do |key, die|
          # options
          if die.option
            die.option.each do |opt|
              @options[opt] = @options[opt] | [key]
            end
          end
          # collections
          if die.collection
            @collections[die.collection] = @collections[die.collection] | [key]
          end
        end

      end
      
    end
		
    # Returns an element's first text node or an attribute's value.
    def content(element_or_attribute)
      case element_or_attribute
      when REXML::Attribute
        return element_or_attribute.value
      when REXML::Element
        return element_or_attribute.text
      end
    end
    
	end  # Proof

end  # XMLProof
