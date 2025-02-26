.PHONY: docs

default: help

## sync: Sync the workspace with the production blog
sync:
	./hugo-notion
	git add content/
	git commit -m "Synced blogs articles"
	@echo "'git push' to push to online prod"

## help: Shows this help
help: Makefile
	@printf ">] ma111e blog\n\n"
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@printf ""
