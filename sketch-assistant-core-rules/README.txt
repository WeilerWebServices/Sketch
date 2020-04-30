# sketch-assistant-core-rules

> 💁‍♀️ This is a "rules only" Assistant, meaning it contains only rule implementations and no
> configuration. Adding this Assistant to Sketch won't do anything because rules need to be
> activated in configuration before they will report anything.
>
> Use this Assistant by extending from it in your own Assistant, and adding configuration and/or
> additional rule implementations. To find out how to do this and more head to the
> [Assistant Developer Documentation](/).
>
> ⚠️ This package is in pre-release mode using the `next` tag.

## Available rules

This Assistant exports the following rules. Click the links to view their documentation,
configuration options and implementation.

- [`artboards-grid`](./src/rules/artboards-grid)
- [`artboards-layout`](./src/rules/artboards-layout)
- [`artboards-max-ungrouped-layers`](./src/rules/artboards-max-ungrouped-layers)
- [`borders-no-disabled`](./src/rules/borders-no-disabled)
- [`debug-all-options`](./src/rules/debug-all-options)
- [`debug-i18n`](./src/rules/debug-i18n)
- [`debug-throws-error`](./src/rules/debug-throws-error)
- [`exported-layers-normal-blend-mode`](./src/rules/exported-layers-normal-blend-mode)
- [`fills-no-disabled`](./src/rules/fills-no-disabled)
- [`groups-max-layers`](./src/rules/groups-max-layers)
- [`groups-no-empty`](./src/rules/groups-no-empty)
- [`groups-no-redundant`](./src/rules/groups-no-redundant)
- [`groups-no-similar`](./src/rules/groups-no-similar)
- [`images-no-outsized`](./src/rules/images-no-outsized)
- [`images-no-undersized`](./src/rules/images-no-undersized)
- [`inner-shadows-no-disabled`](./src/rules/inner-shadows-no-disabled)
- [`layer-styles-no-dirty`](./src/rules/layer-styles-no-dirty)
- [`layer-styles-prefer-library`](./src/rules/layer-styles-prefer-library)
- [`layer-styles-prefer-shared`](./src/rules/layer-styles-prefer-shared)
- [`layers-no-hidden`](./src/rules/layers-no-hidden)
- [`layers-no-loose`](./src/rules/layers-no-loose)
- [`layers-subpixel-positioning`](./src/rules/layers-subpixel-positioning)
- [`name-pattern-artboards`](./src/rules/name-pattern-artboards)
- [`name-pattern-groups`](./src/rules/name-pattern-groups)
- [`name-pattern-images`](./src/rules/name-pattern-images)
- [`name-pattern-pages`](./src/rules/name-pattern-pages)
- [`name-pattern-shapes`](./src/rules/name-pattern-shapes)
- [`name-pattern-symbols`](./src/rules/name-pattern-symbols)
- [`name-pattern-text`](./src/rules/name-pattern-text)
- [`result-messages-include`](./src/rules/result-messages-include)
- [`shadows-no-disabled`](./src/rules/shadows-no-disabled)
- [`shared-styles-no-unused`](./src/rules/shared-styles-no-unused)
- [`symbols-no-unused`](./src/rules/symbols-no-unused)
- [`symbols-prefer-library`](./src/rules/symbols-prefer-library)
- [`text-styles-no-dirty`](./src/rules/text-styles-no-dirty)
- [`text-styles-prefer-library`](./src/rules/text-styles-prefer-library)
- [`text-styles-prefer-shared`](./src/rules/text-styles-prefer-shared)

## Development

The following section of the readme only relates to developing the Assistant, not using it in your
own projects.

### Requirements

- Node
- Yarn

### Scripts

Interact with the tooling in this repository via the following scripts.

| Script            | Description                                     |
| ----------------- | ----------------------------------------------- |
| yarn build        | Builds the Assistant to the `dist` folder       |
| yarn format-check | Checks the formatting with prettier             |
| yarn i18n:extract | Extracts strings from the JS source to PO files |
| yarn test         | Runs the Jest tests                             |
| yarn type-check   | Typecheck the TypeScript                        |

### Workflows

#### Conventional commits

Try and use the [conventional commits](https://www.conventionalcommits.org/) convention when writing
commit messages.

#### Working on rules

Use a TDD approach, and the existing rules as a guide.

Rule functions can run in Node against plain Sketch file JSON, so the Mac Sketch app isn't required
while actively developing rule logic.

When creating a new rule in this repository:

1. Copy and paste one of the existing rule folders in `src/` as a starting point.
1. Add the new rule to the Assistant definition in `src/index.ts`.
1. With Sketch, create some example `.sketch` files to use as test fixtures. At a minimum these
   should demonstrate two scenarios - one where you'd expect your rule to report violations, and one
   where it shouldn't report any
1. While developing your rule and its tests use Jest in watch mode: `yarn test --watch`.
1. If you've added new strings then follow the [internationalization](#internationalization)
   workflow too.
1. Add changeset for your rule, open a Pull Request and once merged [release](#releases) it

#### Releases

This repository uses [Atlassian Changesets](https://github.com/atlassian/changesets) to automate the
npm release process. Read the docs for more information, but the top-level summary is:

- A GitHub Action maintains a permanently open PR that when merged will publish the package to npm
  with the latest changes and an automatically determined semver.
- If the work you do in a PR should affect the next release, then you need to commit a "changeset"
  to the repository together with the rest of your code changes - do this by running
  `yarn changeset`. You'll be asked to provide a change type (major, minor or patch) and a message.

#### Internationalization

This Assistant requires internationalization since it's an official Sketch Assistant.

Translating your own Assistants is completely optional however.

Internationalization is handled by [LinguiJS](https://lingui.js.org), and follows their
[guides](https://lingui.js.org/tutorials/javascript.html) for handling plain JavaScript projects.

The following locales are currently supported in the Sketch Mac app and this project:

- `en` (American English)
- `zh-Hans` (Chinese Simplified)

When ready to perform a round of translation, for example when there are new untranslated strings in
the repository, perform the following workflow:

1. Run `yarn i18n:extract` which will update the `.po` files in `src/locale/` with the new strings
   used throughout the source code.
1. PR and merge these changes to `master`.
1. Translation thereafter happens via [CrowdIn](https://crowdin.com) automation.
