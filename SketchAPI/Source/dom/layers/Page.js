import { DefinedPropertiesKey } from '../WrappedObject'
// eslint-disable-next-line import/no-cycle
import { Group } from './Group'
import { Selection } from '../models/Selection'
import { Types } from '../enums'
import { Factory } from '../Factory'
import { wrapNativeObject, wrapObject } from '../wrapNativeObject'

/**
 * Represents a Page in a Sketch document.
 */
export class Page extends Group {
  /**
   * Make a new page object.
   *
   * @param [Object] properties - The properties to set on the object as a JSON object.
   *                              If `sketchObject` is provided, will wrap it.
   *                              Otherwise, creates a new native object.
   */
  constructor(page = {}) {
    if (!page.sketchObject) {
      // eslint-disable-next-line no-param-reassign
      page.sketchObject = Factory.createNative(Page)
        .alloc()
        .init()
    }

    super(page)
  }

  static getSymbolsPage(document) {
    if (!document) {
      throw new Error('Need to provide a document')
    }
    const wrapped = wrapObject(document)
    return wrapObject(wrapped._getMSDocumentData().symbolsPage())
  }

  static createSymbolsPage() {
    return new Page({
      name: MSPage.defaultSymbolsPageName(),
    })
  }

  // eslint-disable-next-line
  adjustToFit() {
    // obviously doesn't do anything
  }

  duplicate() {
    const object = this._object
    const duplicate = object.copy()
    object.documentData().insertPage_afterPage(duplicate, object)
    return wrapNativeObject(duplicate)
  }

  remove() {
    if (this.isImmutable() || !this._object.documentData()) {
      return this
    }
    this._object
      .documentData()
      .removePages_detachInstances([this._object], true)
    return this
  }

  moveToFront() {
    // doesn't do anything
    return this
  }

  moveToBack() {
    // doesn't do anything
    return this
  }

  moveForward() {
    // doesn't do anything
    return this
  }

  moveBackward() {
    // doesn't do anything
    return this
  }

  // eslint-disable-next-line
  getParentPage() {
    return undefined
  }

  isSymbolsPage() {
    if (!this._object.documentData()) {
      return false
    }
    return this._object.documentData().symbolsPage() == this._object
  }
}

Page.type = Types.Page
Page[DefinedPropertiesKey] = { ...Group[DefinedPropertiesKey] }
Factory.registerClass(Page, MSPage)
Factory.registerClass(Page, MSImmutablePage)

// override setting up a flow which doesn't make sense for a Page
delete Page[DefinedPropertiesKey].flow
delete Page[DefinedPropertiesKey].style
delete Page[DefinedPropertiesKey].locked
delete Page[DefinedPropertiesKey].hidden
delete Page[DefinedPropertiesKey].exportFormats
delete Page[DefinedPropertiesKey].transform
delete Page[DefinedPropertiesKey].smartLayout

// override setting up the parent as it's needs to a be a Document
Page.define('parent', {
  enumerable: false,
  exportable: false,
  get() {
    return wrapNativeObject(this._object.documentData())
  },
  set(document) {
    if (this.isImmutable()) {
      return
    }

    document = wrapObject(document) // eslint-disable-line

    if (this._object.documentData()) {
      if (
        document &&
        this._object.documentData() == document._getMSDocumentData()
      ) {
        // if the parent is the same, then bail out
        return
      }
      this._object
        .documentData()
        .removePages_detachInstances([this._object], false)
    }

    if (!document) {
      return
    }

    document._getMSDocumentData().addPage(this._object)
  },
})

Page.define('index', {
  exportable: false,
  get() {
    const ourLayer = this._object
    return parseInt(ourLayer.parentGroup().indexOfLayer_(ourLayer), 10)
  },
})

Page.define('selected', {
  get() {
    if (this._object.documentData && this._object.documentData()) {
      return this._object.documentData().currentPage() == this._object
    }
    return false
  },

  set(value) {
    if (this.isImmutable()) {
      return
    }
    if (value) {
      this._object.documentData().setCurrentPage(this._object)
    } else {
      // let's just select the first page, not sure what else we could do
      this._object.documentData().setCurrentPageIndex(0)
    }
  },
})

/**
 * The layers that the user has selected.
 *
 * @return {Selection} A selection object representing the layers that the user has selected.
 */
Page.define('selectedLayers', {
  enumerable: false,
  exportable: false,
  importable: false,
  get() {
    return new Selection(this)
  },
})
