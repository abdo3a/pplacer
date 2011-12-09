RELEASE=pplacer guppy rppr
DEBUG=pplacer.d guppy.d rppr.d

all: $(RELEASE)
debug: $(DEBUG)

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
	ledit -x -h .toplevel_history ./$*.top

runcaml:
	ledit -x -h .toplevel_history ocaml

tags:
	taggage `find . -name "*.ml" | grep -v "_build"`

docs: gen_docs.native
	./gen_docs.native
	make -C docs html

.PHONY: $(RELEASE) clean runcaml tags test docs
