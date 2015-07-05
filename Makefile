# OCAMLMAKEFILE := /Users/Edgar/.opam/OCamlMakefile

RESULT := stay_aware
EXEC := stay_aware
OBJC_SOURCE := osx_notifier.m
OBJC_OBJECT := osx_notifier.o
PACKAGES := cmdliner,lwt.unix,rresult

OPT_FLAGS := -ccopt -framework -ccopt AppKit
OCAML_EXEC_SOURCE := main.ml
OSX_NOTIFY := osx_notify.ml

all:objective_c
	ocamlfind ocamlopt $(OPT_FLAGS) -package $(PACKAGES) \
	-I src/osx_notify/ -I src/ -linkpkg \
	src/osx_notify/osx_notifier.o \
	src/osx_notify/osx_notify.ml src/main.ml -o $(EXEC)

objective_c:
	clang -fobjc-arc -c -g src/osx_notify/osx_notifier.m -o \
	src/osx_notify/osx_notifier.o

.PHONY:clean

clean:
	rm -rf *.o *.out *.cmt *.cmo *.cma *.cmx
	rm -rf src/*.out src/*.o src/*.cmt src/*.cmi \
	src/*.cmo src/*.cmo src/*.cma src/*.cmx
	rm -rf src/osx_notify/*.out src/osx_notify/*.o \
	src/osx_notify/*.cmt src/osx_notify/*.cmi \
	src/osx_notify/*.cmo src/osx_notify/*.cmo \
	src/osx_notify/*.cma src/osx_notify/*.cmx
	rm -f $(EXEC)

