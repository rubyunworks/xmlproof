# TomsLib - Tom's Ruby Support Library
# Copyright (c) 2002 Thomas Sawyer, LGPL
#
# REREXML, Basic REXML Modifications
#
# These are some basic enhancements to REXML.
# This does NOT cause any incompatabilities with W3C Recommendations.

# TomsLib is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# TomsLib is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with TomsLib; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


require 'rexml/document'

module REXML

  # Modifications to Instruction class:
  # Adds an attributes instance variable and accessor
  # for treating instruction content (cdata) as a list of attributes.
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

  # Modifications to Namespace module:
  # Adds absolute xpath and index methods.
	module Namespace
  
		# Returns the absolute xpath of the given element
    # Does not include prefixes?
		def absolute_xpath(noroot=false)
      xp = xpath_recurse
      xp.gsub!(/^\//,'')  # remove initial path divider if present
      if noroot
        return xp.gsub(/^\w+\//,'')  # remove first path tag (root)
      else
        return xp
      end
    end
    # Returns the relative xpath of the given element (i.e. no indexes)
    def relative_xpath(noroot=false)
      xp = xpath_recurse(true)
      xp.gsub!(/^\//,'')  # remove initial path divider if present
      if noroot
        return xp.gsub(/^\w+\//,'')  # remove first path tag (root)
      else
        return xp
      end
    end
    def xpath_recurse(rel=false)
      case self
      when REXML::Document
        xp = ""
      when REXML::Element
        if self.parent
          xp = "#{self.parent.xpath_recurse}/#{self.expanded_name}"
          xpi = self.xpath_index(self)
          xp << "[#{xpi}]" if xpi and not rel
        else
          xp = self.expanded_name
          xpi = self.xpath_index(self)
          xp << "[#{xpi}]" if xpi and not rel
        end
      when REXML::Attribute
        if self.element
          xp = "#{self.element.xpath_recurse}/@#{self.expanded_name}"
        else
          xp = self.expanded_name
        end
      end
      return xp
		end
    protected :xpath_recurse
  
    # Returns xpath index of a given element
    def xpath_index(element)
      nm = element.expanded_name
      i = 0
      indice = 0
      element.parent.elements.each do |el|
        i += 1 if el.expanded_name == nm
        indice = i if el == element
      end
      indice = nil if indice < 2 and i < 2
      return indice
    end
    
    # Returns the xpath index total for a given element
    def xpath_index_length(element)
      nm = element.expanded_name
      i = 0
      element.parent.elements.each do |el|
        i += 1 if el.expanded_name == nm
      end
      return i
    end
    alias xpath_index_size xpath_index_length
    
		# !!!!!!! these two will eventually be removed
    alias inherited_prefix prefix
    def inherited_namespace(prefix=inherited_prefix)
      namespace(prefix)  # returns the uri namespace
    end
    
	end  # Namespace

  # Document class modification:
  # Adds instance variables and readers for namespace and schema processing instructions.
  # And turns namespace instructions into ATTRLIST.
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
          i.attributes['name'] = i.attributes['prefix'] = ''
        end
        if i.attributes.has_key?('space')
          i.attributes['uri'] = i.attributes['space']
        elsif i.attributes.has_key?('uri')
          i.attributes['space'] = i.attributes['uri']
        else
					i.attributes['space'] = i.attributes['uri'] = ''
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
    
    # Creates the document attrlist from the namespace instructions
    def create_namespace_attrlist
      @namespace_instructions.each do |nsi|
        self.add_namespace(nsi.attributes['prefix'], nsi.attributes['uri'])
      end
    end
    
  end  # Document

end


