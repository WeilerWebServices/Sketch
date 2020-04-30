import { t } from '@lingui/macro'
import { RuleContext, RuleFunction, FileFormat } from '@sketch-hq/sketch-assistant-types'

import { CreateRuleFunction } from '../..'

export const createRule: CreateRuleFunction = (i18n) => {
  const rule: RuleFunction = async (context: RuleContext): Promise<void> => {
    const { utils } = context
    await utils.iterateCache({
      async group(node): Promise<void> {
        const group = utils.nodeToObject<FileFormat.Group>(node)
        if (group.layers.length === 0) {
          utils.report({
            node,
            message: i18n._(t`Unexpected empty group`),
          })
        }
      },
    })
  }

  return {
    rule,
    name: 'groups-no-empty',
    title: i18n._(t`Groups should not be empty`),
    description: i18n._(
      t`Empty groups can collect in a document over time due to copy and paste errors, and could be considered a document hygiene or usability concern by some teams`,
    ),
  }
}
