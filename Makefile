RELEASE=pplacer guppy rppr
DEBUG=pplacer.d guppy.d rppr.d
DESCRIPT:=pplacer-$(shell uname)-$(shell git describe --tags)

all: $(RELEASE)
debug: $(DEBUG)

# For OPAM
OCAML_TOPLEVEL_PATH = $$OCAML_TOPLEVEL_PATH
ifneq ($(OCAML_TOPLEVEL_PATH),)
	TOPLEVEL_FLAGS=-I ${OCAML_TOPLEVEL_PATH}
endif

$(RELEASE):
	if [ ! -e bin ]; then mkdir bin; fi
	make $@.native
	cp `readlink $@.native` bin/$@
	rm $@.native

%.native %.byte %.p.native:
	ocamlbuild $@

clean:
	rm -rf bin
	rm -f tests.native
	ocamlbuild -clean
	rm -f *.mltop

%.d: %.d.byte
	if [ ! -e bin ]; then mkdir bin; fi
	cp "$<" "bin/$@"

%.top: %.byte
	find _build -name '*.cmo' -print0 | xargs -0I% basename % .cmo > $*.mltop
	ocamlbuild $@
	rm $*.mltop

test: tests.native
	./tests.native

%.runtop: %.top
	rlwrap ./$*.top `find _build -name "*.cmi" | xargs -n1 dirname | sort -u | sed -e 's/^/-I /'` $(TOPLEVEL_FLAGS)

runcaml:
	rlwrap ocaml

tags:
	otags `find . -name "*.ml" | grep -v "_build"`

docs: gen_docs.native
	./gen_docs.native
	make -C docs html
	touch docs/_build/html/.nojekyll

pplacer-linux.zip: $(RELEASE)
	rm -rf $(DESCRIPT)
	mkdir $(DESCRIPT)
	cp -r bin/* scripts $(DESCRIPT)
	zip -r pplacer-linux.zip $(DESCRIPT)/*
	rm -rf $(DESCRIPT)

zip: pplacer-linux.zip

.latest-upload: pplacer-linux.zip
	curl --upload-file ./pplacer-linux.zip https://transfer.sh/$(DESCRIPT).zip > .latest-upload

upload: .latest-upload
	curl -X POST --data-urlencode 'payload={"text": "Latest pplacer uploaded to '$(shell cat .latest-upload)'"}' $(SLACK_URL)


.PHONY: $(RELEASE) clean runcaml tags test docs zip upload
