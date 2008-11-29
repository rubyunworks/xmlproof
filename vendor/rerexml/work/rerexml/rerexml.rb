# REREXML - Basic REXML Modifications
#
# These are some basic enhancements to REXML.
# This does NOT cause any incompatabilities with W3C Recommendations.

require 'rexml/document'

module REXML

	class Instruction

    attr_accessor :attributes

    # Additionally loads contents as a hash of attributes
    alias :orig_initialize :initialize
    def initialize(target, content=nil)
      orig_initialize(target, content)
      if @content
				hash = {}
				@content.scan(/\s*([\w_]+)\s*=\s*(['"])(.*?)\2/).each{ |k,d,v| hash[k] = v }
				@attributes = hash
			else
      	@attributes = nil
      end
    end
    
	end  # Instruction


	module Namespace
  
		# Returns an xpath built up from anscestor names
    # i.e. {root tag name}/.../{this node's tag name}
    # Does not include prefixes
		def absolute_xpath(noroot=false)
      if self.type == REXML::Element
        if self.parent
          if self.parent.name == REXML::Element::UNDEFINED  # we've hit the root
            if noroot
              xp = ""
            else
              xp = name
            end
          else
            xp = "#{self.parent.absolute_xpath(noroot)}/#{self.name}"
          end
        else
          xp = self.name
        end
      elsif self.type == REXML::Attribute
        xp = "#{self.element.absolute_xpath(noroot)}/@#{self.name}"
      end
      if noroot
        return xp.gsub(/^\//,'')
      else
        return xp
      end
		end
	
		# Returns prefix if given (used to provide option for inherits.rb)
		def inherited_prefix
			prefix
		end
		
    # Returns the uri namespace (used to provide option for inherits.rb)
    def inherited_namespace(prefix=inherited_prefix)
      namespace(prefix)
    end
    
	end  # Namespace


  class Document
  
    attr_reader :namespace_instructions, :schema_instructions
    
    alias :orig_initialize :initialize
    def initialize(source=nil, context={})
      orig_initialize(source, context)            # first origianl inititalize
      @namespace_instructions = load_namespaces  # load namespace instrunctions
			@schema_instructions = load_schemas        # load schema instructions
      create_namespace_attrlist
    end
  
    # Loads the namespace xml processing instruction entities. (This is a non-standard notation!)
		def load_namespaces
			namespace_instructions = []
			ns_pi = self.find_all { |i| i.is_a? REXML::Instruction and i.target == 'xml:ns' }
			ns_pi.each do |i|
				if i.attributes.has_key?('name')
          i.attributes['prefix'] = i.attributes['name']
        elsif i.attributes.has_key?('prefix')
          i.attributes['name'] = i.attributes['prefix']
        else
          raise "parse error namespace instruction missing required name or prefix attribute."
        end
        if i.attributes.has_key?('space')
          i.attributes['uri'] = i.attributes['space']
        elsif i.attributes.has_key?('uri')
          i.attributes['space'] = i.attributes['uri']
        else
					raise "parse error namespace instruction missing required space or uri attribute."
				end
        namespace_instructions << i
			end
			return namespace_instructions
		end
		
		# Loads the schema xml processing instruction entities. (This is a non-standard notation!)
		def load_schemas
			schema_instructions = []
			schema_pi = self.find_all { |i| i.is_a? REXML::Instruction and i.target == 'xml:schema' }
			schema_pi.each do |i|
				if i.attributes.has_key?('url')
          i.attributes['source'] = i.attributes['url']
        elsif i.attributes.has_key?('source')
          i.attributes['url'] = i.attributes['source']
        else
          raise "parse error schema instruction missing required url attribute"
        end
        if i.attributes.has_key?('uri')
          i.attributes['space'] = i.attributes['uri']
        elsif i.attributes.has_key?('space')
          i.attributes['uri'] = i.attributes['space']
        else
          raise "parse error schema instruction missing required type attribute"
        end
        schema_instructions << i
			end
			return schema_instructions
		end
    
    #
    def create_namespace_attrlist
      @namespace_instructions.each do |nsi|
        if nsi.attributes['prefix'].empty?
          self.add_namespace("xmlns", nsi.attributes['uri'])
        else
          self.add_namespace("xmlns:#{nsi.attributes['prefix']}", nsi.attributes['uri'])
        end
      end
    end
    
  end

end


