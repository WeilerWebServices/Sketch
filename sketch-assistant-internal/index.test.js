const { resolve } = require('path')
const { testRule } = require('@sketch-hq/sketch-assistant-utils')

const assistant = require('./index')
const config = require('./config')

const testCoreRuleWithConfig = async (fixture, ruleId, numViolations = 1) => {
  const ruleName = `@sketch-hq/sketch-assistant-core-rules/${ruleId}`
  const { violations, errors } = await testRule(
    resolve(__dirname, fixture),
    assistant,
    ruleName,
    config[ruleName],
  )
  expect(violations).toHaveLength(numViolations)
  expect(errors).toHaveLength(0)
}

test('borders-no-disabled', async () => {
  await testCoreRuleWithConfig('./fixtures/disabled-border.sketch', 'borders-no-disabled')
})

test('fills-no-disabled', async () => {
  await testCoreRuleWithConfig('./fixtures/disabled-fill.sketch', 'fills-no-disabled')
})

test('shadows-no-disabled', async () => {
  await testCoreRuleWithConfig('./fixtures/disabled-shadow.sketch', 'shadows-no-disabled')
})

test('inner-shadows-no-disabled', async () => {
  await testCoreRuleWithConfig(
    './fixtures/disabled-inner-shadow.sketch',
    'inner-shadows-no-disabled',
  )
})

test('groups-no-empty', async () => {
  await testCoreRuleWithConfig('./fixtures/empty-group.sketch', 'groups-no-empty')
})

test('layer-styles-no-dirty', async () => {
  await testCoreRuleWithConfig('./fixtures/dirty-style.sketch', 'layer-styles-no-dirty')
})

test('groups-no-redundant', async () => {
  await testCoreRuleWithConfig('./fixtures/redundant-group.sketch', 'groups-no-redundant')
})

test('layers-no-hidden', async () => {
  await testCoreRuleWithConfig('./fixtures/hidden-layer.sketch', 'layers-no-hidden')
})

test('images-no-outsized', async () => {
  await testCoreRuleWithConfig('./fixtures/outsized-image.sketch', 'images-no-outsized')
})

test('text-styles-prefer-shared', async () => {
  await testCoreRuleWithConfig(
    './fixtures/multiple-text-styles.sketch',
    'text-styles-prefer-shared',
    2,
  )
})

test('layer-styles-prefer-shared', async () => {
  await testCoreRuleWithConfig(
    './fixtures/multiple-layer-styles.sketch',
    'layer-styles-prefer-shared',
    2,
  )
})

test('layers-subpixel-positioning', async () => {
  await testCoreRuleWithConfig(
    './fixtures/subpixel-positioning.sketch',
    'layers-subpixel-positioning',
  )
})

test('name-pattern-artboards', async () => {
  await testCoreRuleWithConfig('./fixtures/named-artboards.sketch', 'name-pattern-artboards')
})

test('name-pattern-symbols', async () => {
  await testCoreRuleWithConfig('./fixtures/named-symbols.sketch', 'name-pattern-symbols')
})

test('name-pattern-pages', async () => {
  await testCoreRuleWithConfig('./fixtures/named-pages.sketch', 'name-pattern-pages')
})

test('name-pattern-shapes', async () => {
  await testCoreRuleWithConfig('./fixtures/named-shapes.sketch', 'name-pattern-shapes')
})

test('artboards-max-ungrouped-layers', async () => {
  await testCoreRuleWithConfig(
    './fixtures/artboards-max-ungrouped-layers.sketch',
    'artboards-max-ungrouped-layers',
  )
})

test('images-no-undersized', async () => {
  await testCoreRuleWithConfig('./fixtures/images-no-undersized.sketch', 'images-no-undersized')
})

test('shared-styles-no-unused', async () => {
  await testCoreRuleWithConfig(
    './fixtures/shared-styles-no-unused.sketch',
    'shared-styles-no-unused',
  )
})
