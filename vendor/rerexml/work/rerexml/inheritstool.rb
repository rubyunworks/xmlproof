# REREXML - InheritsTool
# Copyright (c) 2002 Thomas Sawyer, Ruby License
#
# Command line conversion tool for inherits notation.

require 'rerexml/rerexml'
require 'rerexml/inherits'
require 'rexml/contrib/prettyxml'
require 'tomslib/communication'

extend TomsLib::Communication

if $0 == __FILE__

  option = ARGV[0]
  xml_file = ARGV[1]

  if option == '-t'
  
    xml_string = fetch_xml(xml_file)
    xml_document = REXML::Document.new(xml_string)
    new_document = REXML::NamespaceConversion.to_standard(xml_document)
    
    out = ''
    new_document.write(out, -1)
    puts PrettyXML.pretty(out)
      
  elsif option == '-f'
  
    xml_string = fetch_xml(xml_file)
    xml_document = REXML::Document.new(xml_string)
    new_document = REXML::NamespaceConversion.from_standard(xml_document)
    
    out = ''
    new_document.write(out, -1)
    puts PrettyXML.pretty(out)
  
  end

end

