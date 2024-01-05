PROJECT_NAME = xls2ddb

CWD := $(shell pwd)

ifeq (,$(shell which conda))
HAS_CONDA=False
else
HAS_CONDA=True
endif

# Need to specify bash in order for conda activate to work.
SHELL=/bin/bash
# Note that the extra activate is needed to ensure that the activate floats env to the front of PATH
CONDA_ACTIVATE=source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate
# https://stackoverflow.com/questions/53382383/makefile-cant-use-conda-activate

## Set up python interpreter environment
create_environment: ## create conda environment for analysis
ifeq (True,$(HAS_CONDA))
		@echo ">>> Detected conda, creating conda environment."
		mamba env create --force --name $(PROJECT_NAME) -f ./src/environment.yml

		$(MAKE) setup_packages

		@echo ">>> New conda env created. Activate with:\nsource activate $(PROJECT_NAME)"
		
endif


## Set up local packages and DBT
setup_packages: 
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; pip install --editable src/xls2ddb)
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && dbt deps)
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && dbt parse --profiles-dir config)


## Set up python interpreter environment OSX
create_environment_osx: ## create conda environment for analysis
ifeq (True,$(HAS_CONDA))
		@echo ">>> Detected conda, creating conda environment."
		CONDA_SUBDIR=osx-64 mamba env create --force --name $(PROJECT_NAME) -f ./src/environment.yml

		$(MAKE) setup_packages

		@echo ">>> New conda env created. Activate with:\nsource activate $(PROJECT_NAME)"
endif

delete_environment: ## delete conda environment for analysis
	conda remove --name $(PROJECT_NAME) --all -y


## start notebook (jupyter lab)
notebook:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; jupyter lab)


.PHONY: fmt
fmt:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; black src && isort --profile black src && yamllint -c yamllintconfig.yaml .)


.PHONY: lint
lint:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; ruff src && mypy --explicit-package-bases src/xls2ddb)


.PHONY: test
test:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; pytest --ignore=src/pipelines/xls2ddb_dbt/ascii_dbt src)


.PHONY: delete-dangling
delete-dangling:
	 docker rmi $(docker images -f "dangling=true" -q)


## start dagster webserver UI
start-pipeline:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/ && dagster dev)


## SQL DBT debug
sql-debug:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && dbt debug --profiles-dir config)


## SQL DBT run
sql-run:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && dbt run --profiles-dir config --target prod)


## SQL DBT clean
sql-clean:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && dbt clean --profiles-dir config)


## SQL DBT run tests
sql-test:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && dbt test --profiles-dir config --exclude tag:long_running_test)


## SQL interactive duckdb shell
sql-shell:
	duckdb -readonly /path/to/pipeline.duckdb


## SQL DBT docs generate
sql-docs-generate:
# TODO figure out what is going on why do we have to pass the --empty-catalog flag?
# https://getdbt.slack.com/archives/C039D1J1LA2/p1697113630610139
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && dbt docs generate --profiles-dir config --empty-catalog)


## SQL DBT docs serve
sql-docs-serve:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && dbt docs serve --profiles-dir config)


## SQL autoformatter
fmt-sql:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && sqlfluff fix)


## SQL linter
lint-sql:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; cd src/xls2ddb_dbt && sqlfluff lint)


## Start DuckSB Postgres Server on localhost:5433
sql-server-pg:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; python3 -m buenavista.examples.duckdb_postgres /path/to/pipeline.duckdb)

## Start DuckSB Presto Server on localhost:5433
sql-server-presto:
	($(CONDA_ACTIVATE) "${PROJECT_NAME}" ; BUENAVISTA_PORT=5433 DUCKDB_FILE=/path/to/pipeline.duckdb python3 -m buenavista.examples.duckdb_http)


#################################################################################
# PROJECT RULES                                                                 #
#################################################################################
#################################################################################
# Self Documenting Commands                                                     #
#################################################################################
.DEFAULT_GOAL := help
# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
