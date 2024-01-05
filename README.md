# Local Modern Datastack - from Excels to DuckDB

A simple example to show how to stop abusing Excel and steer towards suitable data tools.

Over time it will implement more and more features of the [roadmap](https://github.com/l-mds/roadmap#batch).

## development infrastructure (local setup)

- a computer with internet access to install python packages
- an installed mamba forge https://github.com/conda-forge/miniforge#mambaforge for your operating system
    - ensure the `mamba`command is in your path and working correctly
- an installation of `make` command in your path
- git
- docker
- an SSH key readily set up to connect to github

```bash
git clone git@github.com:l-mds/demo-from-excel-to-duckdb.git
cd demo-from-excel-to-duckdb

make create_environment
```

## available commands

```bash
# without any argumetns - all available commands are listed
make

> create_environment  Set up python interpreter environment 
> create_environment_osx Set up python interpreter environment OSX 
> fmt-sql             SQL autoformatter 
> lint-sql            SQL linter 
> notebook            start notebook (jupyter lab) 
> sql-clean           SQL DBT clean 
> sql-debug           SQL DBT debug 
> sql-docs-generate   SQL DBT docs generate 
> sql-docs-serve      SQL DBT docs serve 
> sql-run             SQL DBT run 
> sql-server-pg       Start DuckSB Postgres Server on localhost:5433 
> sql-server-presto   Start DuckSB Presto Server on localhost:5433 
> sql-shell           SQL interactive duckdb shell 
> sql-test            SQL DBT run tests 
> start-pipeline      start dagster webserver UI 
```
## example case

> TODO set up