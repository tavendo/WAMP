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
	npm install -g grunt-cli
	pip install -r requirements.txt

clean:
	-rm -rf ./.tox
	-rm -rf ./.build
	-rm -rf ./docs/_build/*
	-rm -rf ./docs/_static/gen/*

authors:
	git log --pretty=format:"%an <%ae> %x09" rfc | sort | uniq


build: build_images build_spec docs


#
# build the spec target files from sources
#
BUILDDIR = docs/_static/gen

build_spec: build_spec_rfc build_spec_w3c

build_spec_rfc:
	-mkdir ./.build
	mmark ./rfc/wamp.md > .build/wamp.xml
	xml2rfc --text .build/wamp.xml -o $(BUILDDIR)/wamp_latest_ietf.txt
#xml2rfc --html .build/wamp.xml -o $(BUILDDIR)/wamp_latest_ietf.html

build_spec_w3c:
	grunt

build_spec_rfc_test:
	mmark ./rfc/test.md > .build/test.xml
	xml2rfc --v3 --text .build/test.xml .build/test.txt

build_spec_rfc_test2:
	mmark ./rfc/wamp.md > .build/wamp.xml
	xmllint --noout .build/wamp.xml
	xml2rfc --v3 --text .build/wamp.xml > .build/wamp.txt

# xml2rfc --v3
# https://trac.ietf.org/trac/xml2rfc/ticket/321

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

run_docs: docs
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
