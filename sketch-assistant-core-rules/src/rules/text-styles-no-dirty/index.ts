import { t } from '@lingui/macro'
import { RuleContext, RuleFunction } from '@sketch-hq/sketch-assistant-types'
import FileFormat from '@sketch-hq/sketch-file-format-ts'

import { CreateRuleFunction } from '../..'

type SharedStyle = FileFormat.SharedStyle

export const createRule: CreateRuleFunction = (i18n) => {
  const rule: RuleFunction = async (context: RuleContext): Promise<void> => {
    const { utils } = context

    // Shared styles container, useful to quickly get them in the text
    // node iterator bellow
    const sharedStyles: Map<string, SharedStyle> = new Map()

    await utils.iterateCache({
      // Builds the shared styles container
      async sharedStyle(node) {
        const style: SharedStyle = node as SharedStyle
        if (typeof style.do_objectID === 'string') {
          sharedStyles.set(style.do_objectID, style)
        }
      },
      async text(node): Promise<void> {
        const layer = utils.nodeToObject<FileFormat.Text>(node)
        if (typeof layer.sharedStyleID === 'string') {
          // Get the shared style object
          const sharedStyle = sharedStyles.get(layer.sharedStyleID)
          if (sharedStyle) {
            // Report if this text style differs from its shared style
            if (!layer.style || !utils.textStyleEq(layer.style, sharedStyle.value)) {
              utils.report({
                node,
                message: i18n._(t`Style differs from the shared text style`),
              })
            }
          }
        }
      },
    })
  }

  return {
    rule,
    name: 'text-styles-no-dirty',
    title: i18n._(t`Text styles must be in sync with their shared style`),
    description: i18n._(t`Disallow text styles that differ from their shared styles`),
  }
}
