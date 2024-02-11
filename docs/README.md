# ✨ Welcome to my digital corner
Hello and welcome! This repository hosts [the personal-professional website of myself, Em H](https://em-like-the-dash.vercel.app/). It is built and publcily hosted using a stack I've wanted to play with for a while. The content of the site contains my professional history, and some of my general musings.

👉 [Heck just go to the site](https://em-like-the-dash.vercel.app/)

## About the site
The site is built using [MkDocs](https://www.mkdocs.org) with [Material](https://squidfunk.github.io/mkdocs-material/) for the framework, and is hosted for the public by [Vercel](https://vercel.com/). I think this pairing makes for a pretty simple way to deploy a personal site while still having a CD pipeline, preview links, and a lot of the other stuff that a docs-as-code workflow employs.

I chose MkDocs because it is one of the most popular static site generators for documentation in use today, and is widely popular among docs engineers and technical writers, yet I had never had a chance to play with it before now. Consider me a convert! MkDocs is wonderful!

I chose Vercel because it is a modern CD pipeline host that seems to be growing in popularity, and I wanted to see how it worked. I'm using their free tier, and it was fairly easy to get my site up and running, with some caveats (see "Hosting on Vercel" below).

## Build the site

### Locally with Docker
This is by far the simplest option for local deployment.
#### Prerequisites
- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
#### Steps
1. Clone this repository.
2. Run `docker-compose up`.
3. Hit the local server at `localhost:8000`.

### Locally without Docker
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
4. Next, run `mkdocs serve`:
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

## Hosting on Vercel
[Vercel](https://vercel.com) is a lightweight hosting platform specifically designed for frontends. If you'd like to use my site code to learn Vercel like I did, please do! Here's how.
1. First, fork this repository.
2. Next, create a free account on Vercel.
3. Create your first Vercel project - attach your GitHub account, and import the repository holding this source code.
4. During project configuration, select the branch to use for production deployments (this should probably be the `main` branch for production; however, I also recommend using some test deployments with a test branch BEFORE working off your `main`/production branch).
5. Configure the project's deployment settings with the following values:

| Setting  | Value |
| ------------- | ------------- |
| Build command |  `mkdocs build` |
| Output directory |    `site`   |
| Install command | `pip install -r docs/requirements.txt` |

<img width="1017" alt="image" src="https://github.com/microcosem/em-like-the-dash/assets/58352829/21aeb6a2-fad6-42f4-a2b2-2c792d24e95f">

- The **Build command** for Vercel is the command the host will use to build the site.
- The **Output directory** is the value of `site_dir` in the `mkdocs.yaml` config file. This value defaults to the string `site`, but if you want to change that default, you must explicitly set the desired value in the config file, then change the value of **Output directory** on Vercel to that same value. (See also: [MkDocs: Other Providers](https://www.mkdocs.org/user-guide/deploying-your-docs/#other-providers).)
- The **Install command** value specifies what command should be run to install dependencies, and so forth. In this case, we are telling Vercel to use the Python requirements.txt file to install required packages using `pip`.

These are not all of the configurations that can be specified in Vercel, but these are the minimum requirements to get the site up and running as-is.

> [!NOTE]
I have urllib3 [pinned to versions less than `2.0`](https://github.com/microcosem/em-like-the-dash/blob/main/docs/requirements.txt#L2C1-L2C10), as higher versions were causing issues for Vercel's environment. This is because [Vercel uses Amazon Linux 2](https://vercel.com/docs/deployments/build-image) as the base image for builds, which have older versions of Python [that do not support some newer versions of packages](https://github.com/wagtail/sphinx-wagtail-theme/issues/265).
> At this time, Vercel does not support hosting containerized applications - hence why we're not using Docker to deploy the site there.

# Thanks!
- Thanks [@conceptualshark](https://github.com/conceptualshark) for writing a [great Dockerfile and docker-compose file for MkDocs sites](https://github.com/conceptualshark/conceptualshark.github.io/tree/main).
- Thanks to [@StarfallProjects](https://github.com/StarfallProjects) for [documenting the process of hosting MkDocs with Material on Vercel](https://www.starfallprojects.co.uk/projects/deploy-host-docs/deploy-mkdocs-material-vercel/).
