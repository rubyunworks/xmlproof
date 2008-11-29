# XMLProof/Ruby - Proofreader
# <a schema for the rest of us/>
# Copyright (c) 2002 Thomas Sawyer, Ruby License

require 'xmlproof/proof'
require 'tomslib/communication'

include TomsLib::Communication

module XMLProof

	# Validator class
	class Proofreader
	
    include TomsLib::Communication
  
		attr_reader :errors, :undefined, :xml_document, :proof #, :proofsheets

		def initialize(proof=nil)
      @errors = nil
      @undefined = nil
      @xml_document = nil
      @proof = proof
      #@proofsheets = nil
		end

    # Reinitializes the errors array
    def reset
      @errors = nil
      @undefined = nil
    end

    # Returns whether the last document proofread was valid
    def valid?
      if @errors
        return @errors.empty?
      else
        return nil  # no validation has been run
      end
    end

    # Set proof to use for validation. This also allows for adhoc validation.
    def use_proof(proof) 
      @proof = proof
      #@proofsheets = @proof.proofsheets
    end

    # Set target document to be validated. This also allows for adhoc validation.
    #   if use_internal_proof is false (default), xml can be a string, url, local path or REXML::Document
    #   if use_internal_proof is true, xml must be a url or local path
    def use_document(xml, use_internal_proof=false)
      if use_internal_proof
        proofsheets = Proofsheets.new
        @xml_document = proofsheets.load_document_proofsheets(xml)
        @proof = Proof.new(proofsheets)
      else
        if xml.is_a?(REXML::Document)
          @xml_document = xml_document
        else
          @xml_document = REXML::Document.new(fetch_xml(xml))
        end
      end
    end
    
    
    # Validates a given XML document against set proof.
    def proofread_document(xml)
      use_document(xml)
      proofread  # returns valid?
    end

    # Validates a given XML document against internal schema instructions.
    def proofread_document_internal(xml_url)
      use_document(xml_url, true)
      proofread  # returns valid?
    end
  

    # Returns validity of element or attribute against regexp.
    def regexp?(elora, die=nil)
      die = @proofsheet.die(elora.inherited_namespace, elora.absolute_xpath) if not die
      validity = true  # default /.*/ so default valid is true
      if die
        if die.regexp
          if not md = die.regexp.match(content(elora))
            validity = false
            error = "REGEXP '#{content(elora)}' /#{die.regexp.source}/"
            @errors << [die.namespace, die.xpath, error]
          end
        end
      end
      return validity
    end
    
    # Returns validity of element or attribute against datatype.
    def datatype?(elora, die=nil)
      die = @proofsheet.die(elora.inherited_namespace, elora.absolute_xpath) if not die
      validity = true  # default cdata, so valid
      if die
        if die.datatype
          dts = Datatypes.new
          if not dts.valid?(die.datatype, content(elora))
            validity = false
            error = "DATATYPE '#{content(elora)}' :#{die.datatype}:"
            @errors << [die.namespace, die.xpath, error]
          end
        end
      end
      return validity
    end

		# Returns validity of element against order.
    def order?(element, die=nil)
      die = @proofsheet.die(element.inherited_namespace, element.absolute_xpath) if not die
      validity = true  # default unordered, so valid
      if die
        if die.order and element.has_elements?
					order_how = die.order[0]
          order_has = die.order[1]
          # load childern element tag names into an array
          children = []
          element.elements.each do |child_element|
            children << child_element.name
          end
          # how do you want it?
          case order_how
          when 'tag'
            # remove adjacent duplicates
            packed_children = []
            children.each do |c|
              packed_children << c if packed_children.last != c
            end
            # remove non-intersecting children items
            same_children = packed_children
            diff = children - order_has
            diff.each do |d|
              same_children.delete(d)
            end
            # remove non-intersecting ordered items
            same_has = order_has.dup
            diff =  order_has - same_children
            diff.each do |d|
              same_has.delete(d)
            end
            # correct?
            if same_children != same_has
              validity = false
              error = "ORDER tag"
              @errors << [die.namespace, die.xpath, error]
            end
          when 'content-a..z'
            sorted_children = children.sort
            if not sorted_children == ordered_children
              validity = false
              error = "ORDER content-a..z"
              @errors << [die.namespace, die.xpath, error]
            end
          when 'content-z..a'
            sorted_children = children.sort.reverse
            if not sorted_children == ordered_children
              validity = false
              error = "ORDER content-z..a"
              @errors << [die.namespace, die.xpath, error]
            end
          end
				end
      end
      return validity
    end
    
    # Returns validity of element against closure.
    def closure?(element, die=nil)
      die = @proofsheet.die(element.inherited_namespace, element.absolute_xpath) if not die
      validity = true  # default unordered, so valid
      if die
        if die.closure and element.has_elements?
          closure_how = die.closure[0]
          closure_has = die.closure[1]
          # load childern element tag names into an array
          children = []
          element.elements.each do |child_element|
            children << child_element.name
          end
          case closure_how
          when 'inclusive'
            diff = closure_has - children
            if not diff.empty?
              validity = false
              error = "CLOSURE inclusive"
              @errors << [die.namespace, die.xpath, error]
            end
          when 'exclusive'
            diff = closure_has - children
            if not diff.empty?
              validity = false
              error = "CLOSURE exclusive"
              @errors << [die.namespace, die.xpath, error]
            end
            diff = children - closure_has
            if not diff.empty?
              validity = false
              error = "CLOSURE exclusive"
              @errors << [die.namespace, die.xpath, error]
            end
          end
        end
      end
    end
    
    
    # Returns validity of the applicable array of elements or attributes against range.
    # This markers validates in quasi-relation to the whole document.
    def range?(eloras, die)
      validity = true  # default range, 0..*
      if die
        if die.range
          # divide and count eloras by parent groups
          parent_groups = Hash.new(0)
          eloras.each do |elora|
            case elora
            when REXML::Attribute
              parent_groups[elora.element] += 1
            when REXML::Element
              parent_groups[elora.parent] += 1
            end
          end
          parent_groups.each do |parent, tally|
            if not die.range === tally
              validity = false
              error = "RANGE #{tally} ##{die.range}#"
              @errors << [die.namespace, die.xpath, error]
            end
          end
        end
      end
      return validity
    end
    
    
    # Returns validity against option.
    # This markers validate in relation to the whole document.
    def option?
      if @xml_document
        validity = true
        count = {}
        @proof.options.each do |option, locator_array|
          count[option] = []
          locator_array.each do |locator|
            namespace = locator[0]
            xpath = locator[1]
            REXML::XPath.each(@xml_document, xpath) do |elora|
              count[option] << locator if elora.inherited_namespace == namespace
            end
          end
        end
        count.each do |option, locator_array|
          if locator_array.size > 1 then
            validity = false
            error = "OPTION #{option}"
            @errors << [locator_array[0][0], locator_array[0][1], error]
          end
        end
        return validity
      else
        raise "no XML document provided to validate options against"
      end
    end
    
    # Returns validity against collection.
    # This markers validate in relation to the whole document.
    def collection?
      if @xml_document
        validity = true
        missing = {}
        @proof.collections.each do |collection, locator_array|
          missing[collection] = locator_array.dup
          locator_array.each do |locator|
            namespace = locator[0]
            xpath = locator[1]
            REXML::XPath.each(@xml_document, xpath) do |element_or_attribute|
              missing[collection].delete([namespace, xpath]) if element_or_attribute.inherited_namespace == namespace
            end
          end
        end
        missing.each do |collection, locator_array|
          if not locator_array.empty?
            validity = false
            error = "COLLECTION #{collection}"
            @errors << [locator_array[0][0], locator_array[0][1], error]
          end
        end
        return validity
      else
        raise "no XML document provided to validate collections against"
      end
    end
    

    # Validates entire document against the proofsheet.
    def proofread
      
      @errors = []
      
      # absolute dies
      @proof.absolute_dies.each do |key, die|
        applicable_eloras = REXML::XPath.match(@xml_document, die.xpath).select do |elora|
          die.namespace == elora.inherited_namespace
        end
        validate_eloras(applicable_eloras, die)
      end  
      
      # arbitrary dies
      @proof.arbitrary_dies.each do |key, die|
        applicable_eloras = REXML::XPath.match(@xml_document, die.xpath)
        validate_eloras(applicable_eloras, die)
      end
    
      option?
      collection?
        
      return @errors.empty?  # valid?
    
    end
    
    
    private  # --------------------------------------------------
    
    #
    def validate_eloras(applicable_eloras, die)
      applicable_eloras.each do |elora|
        if elora.is_a?(REXML::Attribute)
          regexp?(elora, die)
          datatype?(elora, die)
        elsif elora.is_a?(REXML::Element)
          regexp?(elora, die)
          datatype?(elora, die)
          order?(elora, die)
          closure?(elora, die)
        end
      end
      range?(applicable_eloras, die)
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

	end # Proofreader

end	 # XMLProof
