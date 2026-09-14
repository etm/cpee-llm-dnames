# CPEE-LLM-DOCUMENTS_NAME

A document-processing service for the cloud process execution engine
(cpee.org), built with [riddl](https://github.com/etm/riddl).

It exposes a single resource:

```
PUT /
```

* `out` — `pipe` or `chat`, selects the response format.
* `user_input` — `text/plain` free-form instruction text.
* `documents` — `application/json`, a JSON array of URLs (strings)
  pointing to the documents to process.

## Installation

* gem install cpee-llm-documents_name

## Scaffold a local install

* cd ~/run
* cpee-llm-documents_name new llm-documents_name

## Configuration

`llm-documents_name.conf` (YAML) sits next to the `llm-documents_name` daemon
script and is loaded automatically on startup:

```yaml
:generic_endpoint: http://localhost:9305/generic/
```

* `generic_endpoint` — the generic LLM endpoint documents are forwarded
  to. Defaults to `http://localhost:9305/generic/` if not set.

Options can also be overridden on the command line:

```
./llm-documents_name -o port=9310 -o generic_endpoint=http://localhost:9305/generic/ -v start
```
