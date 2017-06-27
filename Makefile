rscript = Rscript --no-save --no-restore

# Deployment configuration
deploy_remote ?= origin
deploy_branch ?= master
deploy_source ?= develop

.PHONY: all
all: doc vignettes

.PHONY: deploy
## Deploy the code with documentation to Github
deploy: update-master
	git add --force NAMESPACE
	git add --force man
	git add --force inst/doc
	git commit --message Deployment
	git push --force ${deploy_remote} ${deploy_branch}
	git checkout ${deploy_source}
	git checkout DESCRIPTION # To undo Roxygen meddling with file

.PHONY: update-master
update-master:
	git checkout ${deploy_source}
	git branch --delete --force ${deploy_branch}
	git checkout -b ${deploy_branch}
	${MAKE} doc vignettes

.PHONY: test
## Run unit tests
test:
	${rscript} -e "devtools::test()"

test-%:
	${rscript} -e "devtools::test(filter = '$*')"

.PHONY: vignettes
## Compile all vignettes and other R Markdown articles
vignettes: knit_all
	${rscript} -e "devtools::build_vignettes()"

rmd_files=$(wildcard vignettes/*.rmd)
knit_results=$(patsubst vignettes/%.rmd,inst/doc/%.md,${rmd_files})

.PHONY: knit_all
## Compile R markdown articles and move files to the documentation directory
knit_all: ${knit_results} | inst/doc
	cp -r vignettes/* inst/doc/

inst/doc:
	mkdir -p $@

inst/doc/%.md: vignettes/%.rmd | inst/doc
	${rscript} -e "rmarkdown::render('$<', output_format = 'md_document', output_file = '$@', output_dir = '$(dir $@)')"

.PHONY: doc
## Compile the in-line package documentation
doc:
	${rscript} -e "library(devtools); document()"

## Clean up all build files
cleanall:
	${RM} -r inst/doc
	${RM} -r man

.DEFAULT_GOAL := show-help
# See <https://gist.github.com/klmr/575726c7e05d8780505a> for explanation.
.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)";echo;sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## //;td" -e"s/:.*//;G;s/\\n## /---/;s/\\n/ /g;p;}" ${MAKEFILE_LIST}|LC_ALL='C' sort -f|awk -F --- -v n=$$(tput cols) -v i=19 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"%s%*s%s ",a,-i,$$1,z;m=split($$2,w," ");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;printf"\n%*s ",-i," ";}printf"%s ",w[j];}printf"\n";}'|more $(shell test $(shell uname) == Darwin && echo '-Xr')
