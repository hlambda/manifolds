# Known suffixes.
.SUFFIXES: .aux .bbl .bib .blg .dvi .htm .html .css .log .out .pdf .ps .tex \
	.toc .foo .bar

# Master list of stems of tex files in the project.
# This should be in order.
LIST_STEMS = topological-manifolds smooth-manifolds riemannian-manifolds

# Add index and fdl to get index and license latexed as well.
LIST_FDL = $(LIST_STEMS) fdl index

# Add book to get all stems of tex files needed for tags
LIST_TAGS = $(LIST_FDL) book

# Built in Make functions look like this: $(function arguments)
# In particular: $(patsubst pattern, replacement, text)

# Different extensions
SOURCES = $(patsubst %, %.tex, $(LIST_STEMS)) # add .tex extensions
TAGS = $(patsubst %, tags/tmp/%.tex, $(LIST_TAGS))

TAG_EXTRAS = tags/tmp/my.bib \
	tags/tmp/Makefile tags/tmp/chapters.tex \
	tags/tmp/preamble.tex tags/tmp/bibliography.tex

# Question: What are the foo, bar files used for?
# 	foo is used for aux .tex files and bar is used for aux bbl files.
FOO_SOURCES = $(patsubst %, %.foo, $(LIST_STEMS))
FOOS = $(patsubst %, %.foo, $(LIST_FDL))
BARS = $(patsubst %, %.bar, $(LIST_FDL))

PDFS = $(patsubst %, %.pdf, $(LIST_FDL))
DVIS = $(patsubst %, %.dvi, $(LIST_FDL))

# Be careful. Files in INSTALLDIR will be overwritten!
INSTALLDIR =

# Default latex commands
LATEX := latex -src

PDFLATEX := pdflatex

# Currently the default target runs latex once for each updated tex file.
# This is what you want if you are just editing a single tex file and want
# to look at the resulting dvi file. It does latex the license of the index.
# We use the aux file to keep track of whether the tex file has been updated.
.PHONY: default
default: $(FOO_SOURCES)
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "% This target latexs each updated tex file just once. %"
	@echo "% See the file documentation/make-project for others. %"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

# Target which creates all dvi files of chapters
.PHONY: dvis
dvis: $(FOOS) $(BARS) $(DVIS)
	@echo "Target which creates all dvi files of chapters"

# Target which creates all pdf files of chapters
.PHONY: pdfs
pdfs: $(FOOS) $(BARS) $(PDFS)
	@echo "Target which creates all pdf files of chapters"

# We need the following to cancel the built-in rule for
# dvi files (which uses tex not latex).
%.dvi : %.tex
	@echo "Cancel built-in rule for dvi files"

# Automatically generated tex files
tmp/index.tex: *.tex
	python ./scripts/make_index.py "$(CURDIR)" > tmp/index.tex
	@echo "Generate index file"

tmp/book.tex: *.tex tmp/index.tex
	python ./scripts/make_book.py "$(CURDIR)" > tmp/book.tex
	@echo "Generate book"

# Creating aux files
index.foo: tmp/index.tex
	$(LATEX) tmp/index
	touch index.foo
	@echo "Generate aux index file"


book.foo: tmp/book.tex
	$(LATEX) tmp/book
	touch book.foo
	@echo "Generate aux book file"

%.foo: %.tex
	$(LATEX) $*
	touch $*.foo
	@echo "Creating aux files"

# Creating bbl files
index.bar: tmp/index.tex index.foo
	@echo "Do not need to bibtex index.tex"
	touch index.bar

fdl.bar: fdl.tex fdl.foo
	@echo "Do not need to bibtex fdl.tex"
	touch fdl.bar

book.bar: tmp/book.tex book.foo
	bibtex book
	touch book.bar

%.bar: %.tex %.foo
	bibtex $*
	touch $*.bar

# Creating pdf files
index.pdf: tmp/index.tex index.bar $(FOOS)
	$(PDFLATEX) tmp/index
	$(PDFLATEX) tmp/index
	@echo "Creating index pdf file"

book.pdf: tmp/book.tex book.bar
	$(PDFLATEX) tmp/book
	$(PDFLATEX) tmp/book
	@echo "Creating book pdf file"

%.pdf: %.tex %.bar $(FOOS)
	$(PDFLATEX) $*
	$(PDFLATEX) $*
	@echo "Creating pdf files"

# Creating dvi files
index.dvi: tmp/index.tex index.bar $(FOOS)
	$(LATEX) tmp/index
	$(LATEX) tmp/index
	@echo "Creating index dvi file"

book.dvi: tmp/book.tex book.bar
	$(LATEX) tmp/book
	$(LATEX) tmp/book
	@echo "Creating book dvi file"

%.dvi : %.tex %.bar $(FOOS)
	$(LATEX) $*
	$(LATEX) $*
	@echo "Creating dvi files" # investigate a little more

#
#
# Tags stuff
#
#
#tags/tmp/book.tex: tmp/book.tex tags/tags
#	python ./scripts/tag_up.py "$(CURDIR)" book > tags/tmp/book.tex
#
#tags/tmp/index.tex: tmp/index.tex
#	cp tmp/index.tex tags/tmp/index.tex
#
#tags/tmp/preamble.tex: preamble.tex tags/tags
#	python ./scripts/tag_up.py "$(CURDIR)" preamble > tags/tmp/preamble.tex
#
#tags/tmp/chapters.tex: chapters.tex
#	cp chapters.tex tags/tmp/chapters.tex
#
#tags/tmp/%.tex: %.tex tags/tags
#	python ./scripts/tag_up.py "$(CURDIR)" $* > tags/tmp/$*.tex
#
#tags/tmp/stacks-project.cls: stacks-project.cls
#	cp stacks-project.cls tags/tmp/stacks-project.cls
#
#tags/tmp/stacks-project-book.cls: stacks-project-book.cls
#	cp stacks-project-book.cls tags/tmp/stacks-project-book.cls
#
#tags/tmp/hyperref.cfg: hyperref.cfg
#	cp hyperref.cfg tags/tmp/hyperref.cfg
#
#tags/tmp/my.bib: my.bib
#	cp my.bib tags/tmp/my.bib
#
#tags/tmp/Makefile: tags/Makefile
#	cp tags/Makefile tags/tmp/Makefile
#
## Target dealing with tags
#.PHONY: tags
#tags: $(TAGS) $(TAG_EXTRAS)
#	@echo "TAGS TARGET"
#	$(MAKE) -C tags/tmp
#
#.PHONY: tags_install
#tags_install: tags tarball
#ifndef INSTALLDIR
#	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
#	@echo "% Set INSTALLDIR value in the Makefile!               %"
#	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
#else
#	cp tags/tmp/*.pdf $(INSTALLDIR)
#	tar -c -f $(INSTALLDIR)/stacks-pdfs.tar --exclude book.pdf --transform=s@tags/tmp@stacks-pdfs@ tags/tmp/*.pdf
#	git archive --format=tar HEAD | (cd $(INSTALLDIR) && tar xf -)
#	cp stacks-project.tar.bz2 $(INSTALLDIR)
#	git log --pretty=oneline -1 > $(INSTALLDIR)/VERSION
#endif
#
#.PHONY: tags_clean
#tags_clean:
#	rm -f tags/tmp/*
#	rm -f tmp/book.tex tmp/index.tex
#	rm -f stacks-project.tar.bz2

# Additional targets
.PHONY: book
book: book.foo book.bar book.dvi book.pdf
	@echo "Creating book"

.PHONY: clean
clean:
	rm -f *.aux *.bbl *.blg *.dvi *.log *.pdf *.ps *.out *.toc *.foo *.bar *.pyc
	rm -f tmp/book.tex tmp/index.tex
	rm -f project.tar.bz2
	@echo "Cleaning project"

#.PHONY: distclean
#distclean: clean tags_clean

.PHONY: backup
backup:
	git archive --prefix=project/ HEAD | bzip2 > \
		../project_backup.tar.bz2
		@echo "Backing up project"

.PHONY: tarball
tarball:
	git archive --prefix=project/ HEAD | bzip2 > project.tar.bz2
	@echo "Creating tarball"

# Target which makes all dvis and all pdfs, as well as the tarball
.PHONY: all
all: dvis pdfs book tarball
	@echo "Creating dvis, pdfs, book and tarball"

.PHONY: install
install:
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
	@echo "% To install the project, use the tags_install target %"
	@echo "% Be sure to change INSTALLDIR value in the Makefile! %"
	@echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
