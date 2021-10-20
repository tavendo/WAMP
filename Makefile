.PHONY: docs rfc

# https://github.com/mmarkdown/mmark
# sudo apt install -y mmark
requirements_mmark:
	wget https://github.com/mmarkdown/mmark/releases/download/v2.2.10/mmark_2.2.10_linux_amd64.tgz
	tar xvzf mmark_2.2.10_linux_amd64.tgz
	sudo cp ./mmark /usr/local/bin
	rm -f ./mmark
	rm -f ./mmark*.tgz

requirements:
	sudo apt update
	sudo apt install -y xml2rfc libxml2-utils
	pip install -r requirements.txt
	npm install -g grunt-cli
	npm install

clean:
	-rm -rf ./.tox
	-rm -rf ./docs/_build/*
	-rm -rf ./docs/_static/gen/*
	-rm -rf ./.build
	-mkdir ./.build

authors:
	git log --pretty=format:"%an <%ae> %x09" rfc | sort | uniq


build: build_images build_spec docs


#
# build the spec target files from sources
#
BUILDDIR = docs/_static/gen

build_spec: build_spec_rfc build_spec_w3c

# https://mmark.miek.nl/post/syntax/
build_spec_rfc:
	mmark ./rfc/wamp.md > .build/wamp.xml
	sed -i'' 's/<sourcecode align="left"/<sourcecode/g' .build/wamp.xml
	sed -i'' 's/<t align="left"/<t/g' .build/wamp.xml
	xmllint --noout .build/wamp.xml
	xml2rfc --v3 --text .build/wamp.xml -o $(BUILDDIR)/wamp_latest_ietf.txt
	xml2rfc --v3 --html .build/wamp.xml -o $(BUILDDIR)/wamp_latest_ietf.html

build_spec_w3c:
	grunt


grep_options:
	@find rfc/ -name "*.md" -type f -exec grep -o "\`PUBLISH\.Options\.[a-z_]*|.*\`" {} \;
	@find rfc/ -name "*.md" -type f -exec grep -o "\`EVENT\.Options\.[a-z_]*|.*\`" {} \;
	@find rfc/ -name "*.md" -type f -exec grep -o "\`CALL\.Options\.[a-z_]*|.*\`" {} \;
	@find rfc/ -name "*.md" -type f -exec grep -o "\`INVOCATION\.Options\.[a-z_]*|.*\`" {} \;


#
# build optimized SVG files from source SVGs
#
SCOUR = scour
SCOUR_FLAGS = --remove-descriptive-elements --enable-comment-stripping --enable-viewboxing --indent=none --no-line-breaks --shorten-ids

# build "docs/_static/gen/*.svg" optimized SVGs from "docs/_graphics/*.svg" using Scour
# note: this currently does not recurse into subdirs! place all SVGs flat into source folder
SOURCEDIR = docs/_graphics

SOURCES = $(wildcard $(SOURCEDIR)/*.svg)
OBJECTS = $(patsubst $(SOURCEDIR)/%.svg, $(BUILDDIR)/%.svg, $(SOURCES))

$(BUILDDIR)_exists:
	mkdir -p $(BUILDDIR)

build_images: $(BUILDDIR)_exists $(BUILDDIR)/$(OBJECTS)

$(BUILDDIR)/%.svg: $(SOURCEDIR)/%.svg
	$(SCOUR) $(SCOUR_FLAGS) $< $@

clean_images:
	-rm -rf docs/_static/gen

#
# build the docs (https://wamp-proto.org website) from ReST sources
#
docs:
	tox -e sphinx

docs_only:
	#cd docs && sphinx-build -nWT -b dummy . _build
	cd docs && sphinx-build -b html . _build

clean_docs:
	-rm -rf docs/_build

run_docs:
	twistd --nodaemon web --path=docs/_build --listen=tcp:8010

spellcheck_docs:
	sphinx-build -b spelling -d docs/_build/doctrees docs docs/_build/spelling


#
# build and deploy to:
#
#   * https://s3.eu-central-1.amazonaws.com/wamp-proto.org/
#   * https://wamp-proto.org/
#
publish_docs:
	aws s3 cp --recursive --acl public-read docs/_build s3://wamp-proto.org/
