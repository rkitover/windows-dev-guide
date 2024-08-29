all: README.md .doctoc-stamp .link-check-stamp

README.md: .profile.ps1-include-stamp .nanosetup.ps1-include-stamp \
	.install.ps1-include-stamp .install-user.ps1-include-stamp \
	.ports-task.ps1-include-stamp .build-task.ps1-include-stamp \
	.choco-install.ps1-include-stamp ..vimrc-include-stamp \
	.make.cmd-include-stamp

.%-include-stamp: %
	@echo Inserting updated $<
	@dos2unix -q $<
	@awk -v include_file=$< -f insert-file.awk ./README.md > ./README.md.new
	@cp README.md.new README.md
	@rm README.md.new
	@dos2unix -q ./README.md
	@touch $@

.doctoc-stamp: README.md
	@doctoc --notitle --github README.md
	@touch .doctoc-stamp

ifneq (,$(findstring Windows,$(OS)))
    NPM=npm.cmd
else
    NPM=npm
endif

.link-check-stamp: README.md
	@node --no-deprecation "$(shell $(NPM) root -g)"/markdown-link-check/markdown-link-check -q README.md
	@touch .link-check-stamp

.PHONY: clean

clean:
	@rm .*-stamp
