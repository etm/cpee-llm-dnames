# CPEE-LLM-DNAMES

A document-processing service for the cloud process execution engine
(cpee.org), built with [riddl](https://github.com/etm/riddl).

It exposes a single resource:

```
PUT /
```

* `user_input` — `text/plain` free-form instruction text. Any reference
  to a known document — an exact or slightly misspelled name on its own,
  or a natural phrase like "the X document", "a document named X", "a
  document called X", "a document identified by the name X" — is
  replaced with that document's URL, leaving the surrounding wording
  untouched. Resolution is delegated to the configured LLM, so other
  phrasings may work as well. The resolved text is returned as the
  response.
* `llm` — `text/plain`, the LLM to use.
* `documents` — `application/json`, a JSON object mapping document names
  (the words used to refer to them in `user_input`) to the URLs of the
  documents to process.

## Installation

* gem install cpee-llm-dnames

## Scaffold a local install

* cd ~/run
* cpee-llm-dnames new llm-dnames

## Configuration

`llm-dnames.conf` (YAML) sits next to the `llm-dnames` daemon script and
is loaded automatically on startup:

```yaml
:generic_endpoint: http://localhost:9305/generic/
```

* `generic_endpoint` — the generic LLM endpoint documents are forwarded
  to. Defaults to `http://localhost:9305/generic/` if not set. This is
  typically the generic endpoint of the [cpee-llm](../cpee-llm) module.

Options can also be overridden on the command line:

```
./llm-dnames -o port=9361 -o generic_endpoint=http://localhost:9305/generic/ -v start
```
