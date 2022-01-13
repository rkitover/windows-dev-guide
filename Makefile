all: README.md .doctoc-stamp .link-check-stamp

README.md: .profile-include-stamp .nanosetup-include-stamp .install-include-stamp

.%-include-stamp: %.ps1
	@echo Inserting updated $<
	@dos2unix -q $<
	@awk -v include_file=$< -f insert-file.awk ./README.md > ./README.md.new
	@python -c "from shutil import copyfile; copyfile('README.md.new', 'README.md')"
	@python -c "import os; os.remove('README.md.new')"
	@dos2unix -q ./README.md
	@echo > $@

.doctoc-stamp: README.md
	@doctoc --notitle --github README.md
	@echo > .doctoc-stamp

.link-check-stamp: README.md
	@markdown-link-check -q README.md
	@echo > .link-check-stamp
