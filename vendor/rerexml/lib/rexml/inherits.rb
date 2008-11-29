# REREXML - Inherits
# Copyright (c) 2002 Thomas Sawyer, Ruby License
#
# Enhances REXML to support inherited prefixes and namespaces.
# Also provides conversion tool.
# This notation violates W3C Recommendations!

module REXML

  module Namespace

    # Returns prefix if given, otherwise recurses through parents to find a prefix.
		# NOTE: Does not take into account default prefix-less namespaces. In which case there are no inherited prefixes.
		#       This is in violation of xml standard ;p Prefixes are not inhertited, but they should be!
		def inherited_prefix
      pf = prefix
			if pf.size > 0
				return pf      # has its own prefix
			elsif self.type == REXML::Element
        if parent
          return parent.inherited_prefix
        else
          return nil   # warning: element does not belong to a document (null-namespace)
        end
      elsif self.type == REXML::Attribute
        if element
          return element.inherited_prefix
        else
          return nil  # warning: attribute does not belong to an element (null-namespace)
        end
      elsif self.type == REXML::Document
        if self.namespace_instructions.length > 0
          return self.namespace_instructions[0].attributes['prefix']
        else
          return nil  # null-namespace
        end
      else
        return nil    # warning: what the hell is this then? (null-namespace)
      end
		end


    # Returns the uri space from the matching namespace processing instruction based on the inherited prefix
    def inherited_namespace #(prefix=inherited_prefix)
      if self.type == REXML::Element
        doc = root.parent
      elsif self.type == REXML::Attribute
        doc = element.root.parent
      else
        doc = nil
      end
      if doc
        # THIS SHOULD BE CHANGED TO FIRST DOC XMLNS ATTRIBUTE, NOT INSTRUCTION
        ns_pi = doc.namespace_instructions.find { |i| i.attributes['prefix'] == prefix }
        return ns_pi.attributes['uri']
      else
        return nil
      end
    end
    
  end

  #
  module NamespaceConversion
  
    #
    def NamespaceConversion.to_standard(xml_document)
      
      elements = REXML::XPath.match(xml_document,'//')
      elements.each do |element|
        pf = element.prefix
        if pf.empty?
          element.name = "#{element.inherited_prefix}:#{element.name}"
        end
      end
    
      xml_document.namespace_instructions.each do |nsi|
        xml_document.root.add_namespace(nsi.attributes['prefix'], nsi.attributes['uri'])
        nsi.remove
      end
    
      return xml_document
    
    end
  
  
    def NamespaceConversion.from_standard(xml_source)
      # TO DO
    end
  
  end


end  # REXML

