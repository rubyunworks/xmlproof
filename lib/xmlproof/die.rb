# XMLProof/Ruby - Die
# <a schema for the rest of us/>
# Copyright (c) 2002 Thomas Sawyer, Ruby License

require 'xmlproof/datatypes'

module XMLProof

  # Represents a single parsed proof entry in a tag or attribute
	class Die
	
    attr_reader :arbitrary, :namespace, :xpath
    attr_reader :name, :regexp, :datatype, :range
    attr_reader :order, :closure, :option, :collection, :track
		
		#
		def initialize(cast, elora)
      
      case elora
      when String
        @arbitrary = true
        @namespace = nil
        @xpath = elora
      else
        @arbitrary = false
        @namespace = elora.inherited_namespace
        @xpath = elora.absolute_xpath(true)
      end

      # primary
      @name = nil
      @regexp = nil
      @datatype = nil
      @range = nil    
      
      # secondary
      @order = nil
      @closure = nil
      @option = nil
      @collection = nil
      @track = nil
      
      # parse
      parse_primary(cast)
      parse_secondary(cast, elora) if not @arbitrary
		
		end
	
		# Parses the primary parts of a die
		def parse_primary(cast)
        
				entry = cast
				
        re_name = Regexp.new(/\s+=(.*)=\s+/)
        re_regexp = Regexp.new(/\s*\/(.*)\/\s+/)
        re_datatype = Regexp.new(/\s+:(.*):\s+/)
        re_range = Regexp.new(/\s+#(\d+)(\.\.\.?)([\d]+|[*]?)#\s*/)
        
        md = re_name.match(entry)
        @name = md[1].strip if md
        
        md = re_regexp.match(entry)
				@regexp = Regexp.new(md[1].strip) if md
        
        md = re_datatype.match(entry)
        @datatype = md[1].strip if md
        
        md = re_range.match(entry)
        if md
          # continue parsing range
          atleast = md[1].to_i
          if md[3] == "*"      # open ended
            atmost = (1.0/0.0) # infinite
          else
            if md[2] == ".." 
              atmost = md[3].to_i
            else #...
              atmost = md[3].to_i - 1
            end
          end
          if not atleast > atmost then  # good range
            @range = Range.new(atleast, atmost)
          end
        end
      
      end
      
      # Parses the secondary parts of a die
      def parse_secondary(cast, elora)
        
        entry = cast
        
        re_order = Regexp.new(/\s+@(tag|content-a..z|content-z..a)@\s+/, Regexp::IGNORECASE)
        re_closure = Regexp.new(/\s+\+(inclusive|exclusive)\+\s+/, Regexp::IGNORECASE)
        re_option = Regexp.new(/\s+\?(.*)\?\s+/)
        re_collection = Regexp.new(/\s+\!(.*)\!\s+/)
        re_track = Regexp.new(/\s+\*(yes|true)\*\s+/, Regexp::IGNORECASE)
        
        md = re_order.match(entry)
        if md and elora.is_a?(REXML::Element)
          contains = []
          elora.elements.each do |el|
            contains << el.name
          end
          @order = [ md[1].strip, contains ]
        end
        
        md = re_closure.match(entry)
        if md and elora.is_a?(REXML::Element)
          contains = []
          elora.elements.each do |el|
            contains << el.name
          end
          @closure = [ md[1].strip, contains ]
        end
        
        md = re_option.match(entry)
        @option = md[1].strip.split(',') if md
        
        md = re_collection.match(entry)
        @collection = md[1].strip if md
        
        md = re_track.match(entry)
        @track = true if md
        
			end

			# Returns given cast to die's datatype
			def typecast(x)
        dts = DataTypes.new
				return nil if x == nil  # if nil
        if @datatype
          if dts.valid?(@datatype, x)
            return dts.typecast(@datatype, x)
          end
        end
        return x        
			end

      # Returns whether this control has only a name and is therefore a link
      def link?
        #puts "--", @node.name, @name, @regexp, @datatype, @option, @collection, @count, @order, @set, @track
        return (@name and not @regexp and not @datatype and not @option and not @collection and not @count and not @order and not @track)
      end

      # Class method to link one die to another
      def link(to_die)
        @regexp = to_die.regexp
        @datatype = to_die.datatype
        @range = to_die.range
        if not @arbitrary
          @order = to_die.order
          @closure = to_die.closure
          @option = to_die.option
          @collection = to_die.collection
          @track = to_die.track
        end
      end

  end  # Die
  
end  # XMLProof
