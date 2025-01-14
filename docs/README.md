![Built with Markdown](https://img.shields.io/badge/Markdown-blue) ![Built with Mkdocs](https://img.shields.io/badge/Mkdocs-red)

## ✨ Welcome to my digital corner

Hello and welcome! This repository holds the source for [my personal-professional website](https://emlikethedash.pages.dev).

## About the site

The site is built using [MkDocs](https://www.mkdocs.org) with [Material](https://squidfunk.github.io/mkdocs-material/), and is built and hosted for the public by [Cloudflare Pages](https://pages.cloudflare.com/).

## Building locally

To build the site locally for yourself, you may either [spin up a Docker container](#locally-with-docker) or [run a local development server](#local-development) directly.

### Using Docker and docker-compose

#### Prerequisites

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

#### Steps

1. Clone this repository.
1. Run `docker-compose up`.
1. Hit the local server at `localhost:8000`.

### Local development

#### Prerequisites

- MkDocs
- Python3

#### Steps

1. Clone this repository.
2. From the repository's root, run `mkdocs build`.
  ```zsh
  $ mkdocs build
    
  INFO    -  Cleaning site directory
  INFO    -  Building documentation to directory: emheinz.github.io/site
  ```
3. Next, run `mkdocs serve`:
  ```zsh
  $ mkdocs serve
  
  INFO    -  Building documentation...
  INFO    -  Cleaning site directory
  INFO    -  The following pages exist in the docs directory, but are not included in the "nav" configuration:
               - portfolio.md
  INFO    -  Documentation built in 0.34 seconds
  INFO    -  [13:29:30] Watching paths for changes: 'docs', 'mkdocs.yml'
  INFO    -  [13:29:30] Serving on http://127.0.0.1:8000/
  ```
4. Hit the local server at `localhost:8000`.

## Thanks!

- Thanks [@conceptualshark](https://github.com/conceptualshark) for writing a [great Dockerfile and docker-compose file for MkDocs sites](https://github.com/conceptualshark/conceptualshark.github.io/tree/main).
