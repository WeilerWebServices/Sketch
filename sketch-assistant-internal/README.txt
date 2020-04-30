# sketch-assistant-internal

> 💁‍♀️ This Assistant aims to provide a set of usefully configured rules suitable for dogfooding
> internally at Sketch. Activates and configures rules from the
> [Core Rules Sketch Assistant](https://github.com/sketch-hq/sketch-assistant-core-rules).

[![](https://img.shields.io/badge/-Install%20Internal%20Assistant%20-fa6400.svg?style=flat&colorA=fa6400)](https://sketch-hq.github.io/sketch-assistant-internal)

## Rules

The following rules are part of this Assistant:

- [Artboard Layer Names](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/name-pattern-artboards)
  - must start with an emojii or be numbered. e.g. `1.1 Splash Screen`
- [Artboards Max Ungrouped](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/artboards-max-ungrouped-layers)
  - maxUngroupedLayers: `5`
- [No Blend Modes In Exported Layers](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/exported-layers-no-blend-mode)
- [No Disabled Borders](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/borders-no-disabled)
- [No Disabled Fills](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/fills-no-disabled)
- [No Disabled Shadows](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/shadows-no-disabled)
- [No Disabled Inner Shadows](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/inner-shadows-no-disabled)
- [No Dirty Layer Styles](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/layer-styles-no-dirty)
- [No Dirty Text Styles](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/text-styles-no-dirty)
- [No Empty Groups](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/groups-no-empty)
- [No Hidden Layers](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/layers-no-hidden)
- [No Loose Layers](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/layers-no-loose)
- [No Outsized Images](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/images-no-outsized)
  - maxRatio: `2`
- [No Redundant Groups](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/groups-no-redundant)
- [No Undersized Images](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/images-no-undersized)
  - minRatio: `1`
- [No Unused Shared Styles](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/shared-styles-no-unused)
- [Prefer Shared Layer Styles](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/layer-styles-prefer-shared)
  - maxIdentical: `1`
- [Prefer Shared Text Styles](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/text-styles-prefer-shared)
  - maxIdentical: `1`
- [Symbol Layer Names](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/name-pattern-artboards)
  - names must take advantage of forward-slash grouping, e.g. `Icon/Frog`
- [Group Layer Names](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/name-pattern-artboards)
  - default layer names are forbidden
- [Page Names](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/name-pattern-pages)
  - must start with an emoji, e.g. `🚧 Work in Progress`
- [Shape Names](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/name-pattern-shapes)
  - default layer names are forbidden
- [Subpixel Positioning](https://github.com/sketch-hq/sketch-assistant-core-rules/tree/master/src/rules/layers-subpixel-positioning)
  - scaleFactors: only allows 0.5 subpixel increments

> For the raw config information check [./config.json](config.json)

## Development

The following section of the readme only relates to developing the Assistant, not using it in your
own projects.

### Scripts

Interact with the tooling in this repository via the following scripts.

| Script               | Description                            |
| -------------------- | -------------------------------------- |
| yarn build           | Builds the Assistant                   |
| yarn package-tarball | Packages the Assistant as a local file |

### Configure rules

Update the configuration for existing rules, or add configuration for a new rule like so:

1. Make changes to [./config.json](config.json) file.
1. Make sure to update the [Rules](#rules) section of this readme with an entry
1. Add a [changeset](#releases)
1. Open a pull request to `master` and request a code review.

### Releases

This repository uses [Atlassian Changesets](https://github.com/atlassian/changesets) to automate the
npm release process. Read the docs for more information, but the top-level summary is:

- A GitHub Action maintains a permanently open PR that when merged will publish the package to npm
  with the latest changes and an automatically determined semver.
- If the work you do in a PR should affect the next release, then you need to commit a "changeset"
  to the repository together with the rest of your code changes - do this by running
  `yarn changeset`. You'll be asked to provide a change type (major, minor or patch) and a message.
