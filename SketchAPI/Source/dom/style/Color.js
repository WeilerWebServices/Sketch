import { isNativeObject } from 'util'

/**
 * Given a string description of a color, return an MSImmutableColor.
 */
export function colorFromString(value) {
  return MSImmutableColor.colorWithSVGString_(value)
}

/**
 * Given a MSColor, return string description of a color.
 */
export function colorToString(value) {
  function toHex(v) {
    // eslint-disable-next-line
    return (Math.round(v * 255) | (1 << 8)).toString(16).slice(1)
  }
  const red = toHex(value.red())
  const green = toHex(value.green())
  const blue = toHex(value.blue())
  const alpha = toHex(value.alpha())
  return `#${red}${green}${blue}${alpha}`
}

export class Color {
  constructor(nativeColor) {
    this._object = nativeColor
  }

  static from(object) {
    if (!object) {
      return undefined
    }
    let nativeColor
    if (isNativeObject(object)) {
      if (object.isKindOfClass(MSColor)) {
        nativeColor = MSImmutableColor.alloc().initWithMutableModelObject(
          object
        )
      } else if (object.isKindOfClass(MSImmutableColor)) {
        nativeColor = object
      } else if (object.isKindOfClass(NSColor)) {
        nativeColor = MSImmutableColor.colorWithNSColor(object)
      } else {
        throw new Error(
          `Cannot create a color from a ${String(object.class())}`
        )
      }
    } else if (typeof object === 'string') {
      nativeColor = colorFromString(object)
    } else {
      throw new Error('`color` needs to be a string')
    }

    return new Color(nativeColor)
  }

  toString() {
    return colorToString(this._object)
  }

  toMSColor() {
    return this._object.newMutableCounterpart()
  }

  toMSImmutableColor() {
    return this._object
  }
}
