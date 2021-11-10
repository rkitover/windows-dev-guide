all: .doctoc-stamp

.doctoc-stamp: README.md
	doctoc --notitle --github README.md
	@echo "" > .doctoc-stamp
