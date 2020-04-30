import { t } from '@lingui/macro'
import { RuleContext, RuleFunction, FileFormat } from '@sketch-hq/sketch-assistant-types'

import { CreateRuleFunction } from '../..'

export const createRule: CreateRuleFunction = (i18n) => {
  const rule: RuleFunction = async (context: RuleContext): Promise<void> => {
    const { utils } = context
    await utils.iterateCache({
      async group(node): Promise<void> {
        const group = utils.nodeToObject<FileFormat.Group>(node)
        const usesSharedStyle = typeof group.sharedStyleID === 'string'
        const isStyled = group.style && group.style.shadows && group.style.shadows.length > 0
        const hasOneChild = group.layers.length === 1
        const onlyChildIsGroup = hasOneChild && group.layers[0]._class === 'group'
        if (!usesSharedStyle && !isStyled && hasOneChild && onlyChildIsGroup) {
          utils.report({
            node,
            message: i18n._(t`Unexpected redundant group`),
          })
        }
      },
    })
  }

  return {
    rule,
    name: 'groups-no-redundant',
    title: i18n._(t`Groups should not be redundant`),
    description: i18n._(
      t`Redundant groups are defined as groups that aren't styled and contain only one child. Redundant groups could be considered a document hygiene or usability concern by some teams who may wish to forbid them`,
    ),
  }
}
