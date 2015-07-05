# OCAMLMAKEFILE := /Users/Edgar/.opam/OCamlMakefile

RESULT := stay_aware
EXEC := stay_aware
PACKAGES := cmdliner,lwt.unix,rresult
# Ocamlopt should recognize .m files
OPT_FLAGS := -ccopt -framework -ccopt AppKit -ccopt -ObjC
OCAML_EXEC_SOURCE := main.ml

.PHONY:clean

all:
	ocamlfind ocamlopt $(OPT_FLAGS) \
	-package $(PACKAGES) \
	-I src/osx_notify/ -I src/ -linkpkg \
	src/osx_notify/osx_notifier.c \
	src/osx_notify/osx_notify.ml src/main.ml -o $(EXEC)


clean:
	rm -rf *.o *.out *.cmt *.cmo *.cma *.cmx
	rm -rf src/*.out src/*.o src/*.cmt src/*.cmi \
	src/*.cmo src/*.cmo src/*.cma src/*.cmx
	rm -rf src/osx_notify/*.out src/osx_notify/*.o \
	src/osx_notify/*.cmt src/osx_notify/*.cmi \
	src/osx_notify/*.cmo src/osx_notify/*.cmo \
	src/osx_notify/*.cma src/osx_notify/*.cmx
	rm -f $(EXEC)
