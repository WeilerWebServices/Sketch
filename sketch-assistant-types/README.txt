# sketch-assistant-types

TypeScript types for Sketch Assistants.

> 🙋‍♀️ The types exported from this module are generally useful to any TypeScript project related to
> Assistants, including the development of individual Assistant packages themselves.

## Usage

```sh
yarn add @sketch-hq/sketch-assistant-types@next
```

> ⚠️ The package is in pre-release mode using the `next` tag.

## Development

This section of the readme is related to developing the package. If you just want to consume the
package you can safely ignore this.

### Scripts

| Script            | Description                         |
| ----------------- | ----------------------------------- |
| yarn build        | Builds package to `dist`            |
| yarn format-check | Checks the formatting with prettier |

### Workflows

#### Conventional commits

Try and use the [conventional commits](https://www.conventionalcommits.org/) convention when writing
commit messages.

#### Releases

This repo uses [Atlassian Changesets](https://github.com/atlassian/changesets) to automate the npm
release process. Read the docs for more information, but the top-level summary is:

- A GitHub Action maintains a permanently open PR that when merged will publish the package to npm
  with the latest changes and an automatically determined semver
- If the work you do in a PR should affect the next release, then you need to commit a "changeset"
  to the repo together with the rest of your code changes - do this by running `yarn changeset`.
  You'll be asked to provide a change type (major, minor or patch) and a message
