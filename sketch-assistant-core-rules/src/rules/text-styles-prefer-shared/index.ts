import { t, plural } from '@lingui/macro'
import { RuleContext, RuleFunction, Node, FileFormat } from '@sketch-hq/sketch-assistant-types'

import { CreateRuleFunction } from '../..'

function assertMaxIdentical(val: unknown): asserts val is number {
  if (typeof val !== 'number') {
    throw new Error()
  }
}

export const createRule: CreateRuleFunction = (i18n) => {
  const rule: RuleFunction = async (context: RuleContext): Promise<void> => {
    const { utils } = context
    // Gather option value and assert its type
    const maxIdentical = utils.getOption('maxIdentical')
    assertMaxIdentical(maxIdentical)
    const results: Map<string, Node[]> = new Map()
    await utils.iterateCache({
      async text(node): Promise<void> {
        const layer = utils.nodeToObject<FileFormat.Text>(node)
        if (typeof layer.sharedStyleID === 'string') return // Ignore layers using a shared style
        // Determine whether we're inside a symbol instance, if so return early since
        // duplicate layer styles are to be expected across the docucument in instances
        const classes: string[] = [node._class]
        utils.iterateParents(node, (parent) => {
          if (typeof parent === 'object' && '_class' in parent) classes.push(parent._class)
        })
        if (classes.includes('symbolInstance')) return
        // Get a string hash of the style object.
        const hash = utils.textStyleHash(layer.style)
        // Add the style object hash and current node to the result set
        if (results.has(hash)) {
          const nodes = results.get(hash)
          nodes?.push(node)
        } else {
          results.set(hash, [node])
        }
      },
    })
    // Loop the results, generating violations as needed
    for (const [, nodes] of results) {
      const numIdentical = nodes.length
      if (numIdentical > maxIdentical) {
        utils.report(
          nodes.map((node) => ({
            node,
            message: i18n._(
              plural({
                value: maxIdentical,
                one: `Expected no identical text styles in the document, but found ${numIdentical} matching this layer's text style. Consider a shared text style instead`,
                other: `Expected a maximum of # identical text styles in the document, but found ${numIdentical} instances of this layer's text style. Consider a shared text style instead`,
              }),
            ),
          })),
        )
      }
    }
  }

  return {
    rule,
    name: 'text-styles-prefer-shared',
    title: (ruleConfig) =>
      i18n._(t`No more than ${ruleConfig.maxIdentical} text styles can be identical`),
    description: i18n._(
      t`Teams may wish to enforce the usage of shared text styles within a document, and the presence of identical text styles represent an opportunity to refactor them to use a single shared style`,
    ),
    getOptions: (helpers) => [
      helpers.integerOption({
        name: 'maxIdentical',
        title: i18n._(t`Max Identical`),
        description: i18n._(t`Maximum number of identical text styles allowable in the document`),
        minimum: 1,
        defaultValue: 1,
      }),
    ],
  }
}
