# CPEE-LLM-DNAMES

A document-processing service for the cloud process execution engine
(cpee.org), built with [riddl](https://github.com/etm/riddl).

It exposes a single resource:

```
PUT /
```

* `user_input` — `text/plain` free-form instruction text. Any word in it
  that names a document (preceded by whitespace, followed by `.`, `!`,
  `?`, or end of line — slight misspellings are tolerated) is replaced
  with that document's URL. The resolved text is returned as the
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

Options can be overridden on the command line:

```
./llm-dnames -o port=9361 -v start
```
