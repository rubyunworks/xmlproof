# XMLProof/Ruby - About
# <a schema for the rest of us/>
# Copyright (c) Thomas Sawyer, Ruby License

module XMLProof
  
  TITLE = "XMLProof/Ruby"
	RELEASE = "02.06.13"
	STATUS = "RC1"
	AUTHOR = "Thomas Sawyer"
	EMAIL = "transami@transami.net"
  
	Package = "#{TITLE}"
	Version = "v#{RELEASE} #{STATUS}"
	Copyright = "Copyright © 2002 #{AUTHOR}, #{EMAIL}"

  def XMLProof.about
    puts
    puts XMLProof::Package
    puts XMLProof::Version
    puts XMLProof::Copyright
    puts
  end

end

# Write about info to standerd out
if $0 == __FILE__
	XMLProof.about
end