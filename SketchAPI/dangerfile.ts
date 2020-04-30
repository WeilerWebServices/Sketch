import * as path from 'path'
import { danger, warn, fail } from 'danger'

const touchedFiles = danger.git.modified_files.concat(danger.git.created_files)

const LIB_REGEX = /^Source\/.*\.js$/

const libraryChanges = touchedFiles.filter(
  filePath => LIB_REGEX.test(filePath) && filePath.indexOf('__tests__') === -1
)

function hasMatchingTest(change: string) {
  const { dir, name } = path.parse(change)
  const testPath = path.join(dir, '__tests__', `${name}.test.js`)
  return touchedFiles.find(f => f === testPath)
}

function hasMatchingDoc(change: string) {
  const { name } = path.parse(change)
  const docPath = path.join('docs', 'api', `${name}.md`)
  return touchedFiles.find(f => f === docPath)
}

function hasMatchingTypes(change: string) {
  // placeholder which will be filed when we have typescript types
  return !!change
}

/**
 * CHECK FOR CHANGELOG UPDATE
 */

const hasCHANGELOGChanges = touchedFiles.some(
  filePath => filePath === 'CHANGELOG.json'
)
const hasLibraryChanges = libraryChanges.length > 0

if (hasLibraryChanges && !hasCHANGELOGChanges) {
  warn('This pull request may need a CHANGELOG entry.')
}

/**
 * CHECK FOR PACKAGE.JSON UPDATE
 */
const packageChanged = touchedFiles.some(
  filePath => filePath === 'package.json'
)
const lockfileChanged = touchedFiles.some(
  filePath => filePath === 'package-lock.json'
)

if (packageChanged && !lockfileChanged) {
  const message =
    'Changes were made to package.json, but not to package-lock.json'
  const idea = 'Perhaps you need to run `npm run install`?'
  warn(`${message} - <i>${idea}</i>`)
}

const corePackageChanged = touchedFiles.some(
  filePath => filePath === 'core-modules/package.json'
)

if (corePackageChanged) {
  // eslint-disable-next-line
  const coreModules = require('./core-modules/package.json')

  if (
    Object.keys(coreModules.dependencies).some(
      k => coreModules.dependencies[k][0] === '^'
    )
  ) {
    fail('core-modules/package.json should only contain pinned dependencies')
  }
}

/**
 * CHECK FOR TESTS
 */

const ignoredFilesForTests = [
  'Source/async/index.js',
  'Source/data-supplier/index.js',
  'Source/dom/index.js',
  'Source/settings/index.js',
  'Source/ui/index.js',
  'Source/test-utils.js',
  'Source/index.js',
]

const ignoredFilesForDocs = [
  'Source/async/index.js',
  'Source/data-supplier/index.js',
  'Source/dom/enums.js',
  'Source/dom/Factory.js',
  'Source/dom/index.js',
  'Source/dom/utils.js',
  'Source/dom/wrapNativeObject.js',
  'Source/dom/WrappedObject.js',
  'Source/settings/index.js',
  'Source/ui/index.js',
  'Source/test-utils.js',
  'Source/index.js',
]

const ignoredFilesForTypes: string[] = []

// Warn if there are library changes, but not tests
libraryChanges.forEach(change => {
  const missingMatchingTest =
    ignoredFilesForTests.indexOf(change) === -1 && !hasMatchingTest(change)
  const missingMatchingDoc =
    ignoredFilesForDocs.indexOf(change) === -1 && !hasMatchingDoc(change)
  const missingMatchingTypes =
    ignoredFilesForTypes.indexOf(change) === -1 && !hasMatchingTypes(change)

  if (missingMatchingTest || missingMatchingDoc || missingMatchingTypes) {
    warn(
      `\`${change}\` changed, but not:
  ${missingMatchingDoc ? '- 📚 its docs\n' : ''}${
        missingMatchingTest ? '- 🧪 its tests\n' : ''
      }${missingMatchingTypes ? '- ⌨️ its types\n' : ''}
That's OK as long as you're refactoring.`
    )
  }
})
