
# Requires asciidoctor:
# $ sudo apt-get install asciidoctor

# To get syntax highlighting:
# $ gem install rouge

asciidoctor \
	-a webfonts! \
	--safe-mode=safe \
	--destination-dir=html5 \
	--backend=html5 \
	--doctype=article \
	*.adoc
