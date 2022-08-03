cp=python -c 'from sys import argv; from shutil import copyfile; copyfile(*argv[1:3]);'
rm=python -c "from sys import argv; import os; os.remove(argv[1])"
touch=echo >

all: README.md .doctoc-stamp .link-check-stamp

README.md: .profile-include-stamp .nanosetup-include-stamp \
	.install-include-stamp .ports-task-include-stamp .build-task-include-stamp

.%-include-stamp: %.ps1
	@echo Inserting updated $<
	@dos2unix -q $<
	@awk -v include_file=$< -f insert-file.awk ./README.md > ./README.md.new
	@$(cp) README.md.new README.md
	@$(rm) README.md.new
	@dos2unix -q ./README.md
	@$(touch) $@

.doctoc-stamp: README.md
	@doctoc --notitle --github README.md
	@$(touch) .doctoc-stamp

.link-check-stamp: README.md
	@markdown-link-check -q README.md
	@$(touch) .link-check-stamp
