/* globals expect, test */
import { canBeLogged } from '../../../test-utils'
import { Artboard } from '../..'

test('should create an artboard', () => {
  const artboard = new Artboard({ name: 'Test' })
  expect(artboard.type).toBe('Artboard')
  canBeLogged(artboard, Artboard)
})

test('should set the artboard as a flow start point', () => {
  const artboard = new Artboard({ name: 'Test', flowStartPoint: true })

  expect(artboard.flowStartPoint).toBe(true)
})

test('should set the background', () => {
  const artboard = new Artboard()

  // defaults
  expect(artboard.background.toJSON()).toEqual({
    enabled: false,
    includedInExport: true,
    color: '#ffffffff',
  })

  artboard.background.color = '#123456ff'
  expect(artboard.background.color).toBe('#123456ff')

  artboard.background.enabled = true
  expect(artboard.background.enabled).toBe(true)

  artboard.background.includedInExport = false
  expect(artboard.background.includedInExport).toBe(false)

  artboard.background = {
    color: '#00000000',
    enabled: false,
    includedInExport: true,
  }
  expect(artboard.background.toJSON()).toEqual({
    enabled: false,
    includedInExport: true,
    color: '#00000000',
  })
})
