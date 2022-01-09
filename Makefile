all: .profile-stamp .doctoc-stamp

.profile-stamp: profile.ps1
	@echo Inserting updated profile.ps1
	@dos2unix ./profile.ps1
	@awk -f insert-profile.awk ./README.md > ./README.md.new
	@cmake -E copy ./README.md.new ./README.md
	@cmake -E remove -f ./README.md.new
	@dos2unix ./README.md
	@echo > .profile-stamp

.doctoc-stamp: .profile-stamp README.md
	doctoc --notitle --github README.md
	@echo > .doctoc-stamp
