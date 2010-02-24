# TkXML
# by Thomas Sawyer (transami@runbox.com)
# version April 2002 - Alpha (2.04a)
# A combination of Ruby/Tk + REXML to allow for fast and easy creation of Tk interfaces using standard XML

require 'REXML/document'
require 'tk'

include REXML

class TkXML

	def initialize(source)
		@listener = TkXML_Listener.new
		Document.parse_stream(source, @listener)
	end

	def build
		Tk.mainloop
	end

end

class TkXML_Listener

	def initialize
		puts "Initializing TkXML_Listner"
		@widget = Hash.new
		@widget_stack = Array.new
		@parent = nil
	end

	def tag_start name, attributes
		
		# get parent, the widget on the bottom of the stack
		@parent = @widget_stack.last
		
		# pull off the tag name if prefixed with the Tk namespace
		if name[0..2] == "Tk:"
			tag_name = name[3..name.length]
		else
			tag_name = name
		end
		
		# looks life the attributes object given is nothing morethen a array in an array. how lame!
		# this wll turn it into a hash
		attr_hash = Hash.new
		attributes.each do |a|
			attr_hash[a[0]] = a[1]
		end
		
		# okay, lets do this thing
		
		# is it a method call or a new widget?
		if tag_name[0..0] == '_'
		
			# apply method
			puts "Applying Method: #{name} to #{@parent}"
			
			# get method name
			meth_name = tag_name[1..tag_name.length]
			
			# assign the method's parameters
			p_arr = Array.new	# array for parameters to be passed
			p_init = Hash.new	# for the ordered arguments _1 _2 etc.
			p_hash = Hash.new	# for all other named parameters
			
			# weed out the ordered parameters from the hash parameters
			attr_hash.each do |n, v|
				puts "   #{n} => #{v}"
				if n[0..0] == "_"
					p_init[n] = v
				else
					p_hash[n] = v
				end
			end

			# sort the ordered parameters based on the hash key
			# note: this converts p_init into an associative array
			# then place each one in the parameter array
			if not p_init.empty?
				p_init.sort
				p_init.each do |a|
					p_arr.push a[1]
				end
			end
			
			# now add the hash to the array if there is one
			if not p_hash.empty?
				p_arr.push p_hash
			end
			
			# call the method
			@parent.send(meth_name, *p_arr)
		
		else

			# create widget
			puts "Creating Widget: #{name} of #{@parent}"

			widget_class = "Tk" + tag_name.capitalize
			widget_name = attr_hash['name']

			if @parent == nil
				@widget[widget_name] = Tk.const_get(widget_class).new
			else
				@widget[widget_name] = Tk.const_get(widget_class).new(@parent)
			end
			
			# assign the widget properties
			attr_hash.each do |n, v|
				if not n == 'name'
					puts "   #{n} => #{v}"
					@widget[widget_name].send(n, v)
				end
			end

			# push widget on to the stack
			@widget_stack.push(@widget[widget_name])
		
		end
	
	end


	def tag_end name
	
		# pull off the tag name if prefixed with the Tk namespace
		if name[0..2] == "Tk:"
			tag_name = name[3..name.length]
		else
			tag_name = name
		end
		
		# if method then we're finish
		# else if widget then finish creation and pop off the widget stack
		if tag_name[0..0] == "_"
		
			puts "End Method: #{name}"
		
		else
		
			@parent = @widget_stack[-2]
			current = @widget_stack.last
			
			case tag_name.downcase
				when "menu"
					@parent.menu(current)
			end
			
			# pop current widget off of stack
			@widget_stack.pop
			
			puts "End Widget: #{name}"
			
		end
		
	end

	
	def text free_radical
		if not free_radical.strip == ""
			puts "Error: TkXML does not use XML text entries: #{free_radical}"
		end
	end

end
