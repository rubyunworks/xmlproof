require 'tkxml'

xml_file = File.open("ui.xml")
tkxml_instance = TkXML.new(xml_file)
tkxml_instance.build


