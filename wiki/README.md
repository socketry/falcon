# Wiki

## Usage

If you don't have Ruby installed yet, please do so using your system's package manager.

### Initial Installation

To install the Ruby gems to serve your wiki:

	bundle install

### Local Server

To start the wiki locally:

	bake utopia:wiki:serve

You can then access the wiki: https://localhost:9292

### Static Site

To generate a static site:

	bake utopia:wiki:static

This will generate a complete static copy of the wiki in the `static/` directory.
