# XMLProof/Ruby - Datatypes
# <a schema for the rest of us/>
# Copyright (c) Thomas Sawyer, Ruby License

require 'parsedate'

module XMLProof
  
  #
  class Datatypes
  
    # REGULAR EXPRESSION CONSTANTS
    SYMBOL = /^[a-zA-Z0-9_]+$/
    BOOLEAN = /^(yes|true|1|on|no|false|0|off|-1|nil)$/ 
    BOOLEAN_TRUE = /^(yes|true|1|on)$/ 
    BOOLEAN_FALSE = /^(no|false|0|off|-1|nil)$/ 
    STRING = /.*/
    INTEGER = /^([+]|[-])?\d+$/
    UNSIGNED_INTEGER = /^\d+$/
    FLOAT = /^[-+]?\d*\.?\d+$/
    TIME = /\d+:\d+/
    TIMESTAMP = /20\d{2}(-|\/)((0[1-9])|(1[0-2]))(-|\/)((0[1-9])|([1-2][0-9])|(3[0-1]))(T|\s)(([0-1][0-9])|(2[0-3])):([0-5][0-9]):([0-5][0-9])/
    EMAIL = /^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/
    UK_POSTCODE = /^[a-zA-Z]{1,2}[0-9][0-9A-Za-z]{0,1} {0,1}[0-9][A-Za-z]{2}$/
    US_POSTCODE = /^\d{5}-\d{4}|\d{5}|[A-Z]\d[A-Z] \d[A-Z]\d$/
    INDIAN_POSTCODE = /^\d{3}\s?\d{3}$/
    US_PHONE = /^\D?(\d{3})\D?\D?(\d{3})\D?(\d{4})$/
    DUTCH_PHONE = /(^\+[0-9]{2}|^\+[0-9]{2}\(0\)|^\(\+[0-9]{2}\)\(0\)|^00[0-9]{2}|^0)([0-9]{9}$|[0-9\-\s]{10}$)/
    IP4 = /^(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])$/
    CREDITCARD = /^(\d{4}[- ]){3}\d{4}|\d{16}$/
    CREDITCARD_MAJOR =  /^((4\d{3})|(5[1-5]\d{2})|(6011))-?\d{4}-?\d{4}-?\d{4}|3[4,7]\d{13}$/
    UK_INSURANCE = /^[A-Za-z]{2}[0-9]{6}[A-Za-z]{1}$/
    ISBN = /^\d{9}[\d|X]$/
    US_CURRENCY =  /^\$?([0-9]{1,3},([0-9]{3},)*[0-9]{3}|[0-9]+)(.[0-9][0-9])?$/
    SSN = /^\d{3}-\d{2}-\d{4}$/


    attr_reader :datatypes
  
    def initialize
      
      @datatypes = {
        'symbol' => { 'valid' => proc {|x| SYMBOL.match(x)}, 'typecast' => proc {|x| x.to_s} },
        'boolean' => { 'valid' => proc {|x| BOOLEAN.match(x)}, 'typecast' => proc {|x| x === BOOLEAN_TRUE} },
        'bool' => { 'valid' => proc {|x| BOOLEAN.match(x)}, 'typecast' => proc {|x| x === BOOLEAN_TRUE} },
        'yesno' => { 'valid' => proc {|x| BOOLEAN.match(x)}, 'typecast' => proc {|x| x === BOOLEAN_TRUE} },
        'string' => { 'valid' => proc {|x| STRING.match(x)}, 'typecast' => proc {|x| x.to_s} },
        'text' => { 'valid' => proc {|x| STRING.match(x)}, 'typecast' => proc {|x| x.to_s} },
        'varchar' => { 'valid' => proc {|x| STRING.match(x)}, 'typecast' => proc {|x| x.to_s} },
        'var' => { 'valid' => proc {|x| STRING.match(x)}, 'typecast' => proc {|x| x.to_s} },
        'char' => { 'valid' => proc {|x| STRING.match(x)}, 'typecast' => proc {|x| x.to_s} },
        'int' => { 'valid' => proc {|x| INTEGER.match(x)}, 'typecast' => proc {|x| x.to_i} },
        'integer' => { 'valid' => proc {|x| INTEGER.match(x)}, 'typecast' => proc {|x| x.to_i} },
        'serial' => { 'valid' => proc {|x| INTEGER.match(x)}, 'typecast' => proc {|x| x.to_i} },
        'unsigned' => { 'valid' => proc {|x| UNSIGNED_INTEGER.match(x)}, 'typecast' => proc {|x| x.to_i} },
        'float' => { 'valid' => proc {|x| FLOAT.match(x)}, 'typecast' => proc {|x| x.to_f} },
        'double' => { 'valid' => proc {|x| FLOAT.match(x)}, 'typecast' => proc {|x| x.to_f} },
        'decimal' => { 'valid' => proc {|x| FLOAT.match(x)}, 'typecast' => proc {|x| x.to_f} },
        'numeric' => { 'valid' => proc {|x| FLOAT.match(x)}, 'typecast' => proc {|x| x.to_f} },
        'time' => { 'valid' => proc {|x| TIME.match(x)}, 'typecast' => proc {|x| x.to_s} },
        'timestamp' => { 'valid' => proc {|x| TIMESTAMP.match(x)}, 'typecast' => proc {|x| x.to_s} },
        'date' => { 'valid' => proc {|x| complex_date_valid?(x)}, 'typecast' => proc {|x| x.to_s} },
        'ssn' => { 'valid' => proc {|x| SSN.match(x)}, 'typecast' => proc {|x| x.to_s} }
      }
      
    end
  
    #
    def add_datatype(datatype_name, valid_proc, typecast_proc)
      @datatypes[datatype_name] = { 'valid' => valid_proc, 'typecast' => typecast_proc }
    end
    
    #
    def remove_datatype(datatype_name)
      @datatypes[datatype_name].remove
    end
    
    #
    def valid?(datatype_name, value)
      validity = true  # assume cdata, so true
      if @datatypes.has_key?(datatype_name)
        if not @datatypes[datatype_name]['valid'].call(value.to_s)
          validity = false
        end
      end
      return validity
    end
    
    #
    def typecast(datatype_name, value)
      if @datatypes.has_key?(datatype_name)
        return @datatypes[datatype_name]['typecast'].call(value.to_s)
      end
    end
    
    #
    def complex_date_valid?(date_string)
      pd = ParseDate.parsedate(date_string)
      if pd[0]
         return true
      else
        return false
      end
    end

  end  # Datatypes
  
end  # XMLProof

