# GitHub Copilot Instructions

## Use Agent Context

When working on this project, consult the `agents.md` file for project-specific guidelines, architecture decisions, and development patterns. This file contains curated information that will help you make better decisions aligned with the project's goals and standards.

If the file does not exist, you will need to install it, by running the following command:

```bash
$ bundle install
$ bundle exec bake agent:context:install
```

This command will set up the necessary context files that help you understand the project structure, dependencies, and conventions.

## Ignoring Files

The `.gitignore` file is split into two sections, separated by a blank line. The first section is automatically generated, while the second section is user controlled.

While working on pull requests, you should not add unrelated changes to the `.gitignore` file as part of the pull request.
