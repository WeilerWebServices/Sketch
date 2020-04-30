const sketch = require('sketch')
const { DataSupplier, UI } = sketch
const util = require('util')
const config = {}

// Get your own API key at https://translate.yandex.com/developers/keys :)
const YANDEX_API_KEY = "trnsl.1.1.20180912T154941Z.a526333405a74b23.f809d9991b4d9e56bf40c95e7d5325513669a25b"
const API_URL = `https://translate.yandex.net/api/v1.5/tr.json/`

export function onStartup () {
  // Register the plugin
  DataSupplier.registerDataSupplier('public.text', 'Translate to Random Language', 'SupplyTranslation')
}

export function onShutdown () {
  // Deregister the plugin
  DataSupplier.deregisterDataSuppliers()
}

export function onSupplyTranslation (context) {
  getAvailableLanguages()
    .then(langs => {
      UI.message('🕑 Translating…')
      let dataKey = context.data.key
      const items = util.toArray(context.data.items).map(sketch.fromNative)
      items.forEach((item, index) => {
        let targetLanguage = langs[Math.floor(Math.random()*langs.length)]
        detectLanguageFor(item.text)
          .then(sourceLanguage => translateText(item.text, sourceLanguage, targetLanguage))
          .then(translation => {
            DataSupplier.supplyDataAtIndex(dataKey, translation, index)
            UI.message(null)
          })
      })
    }).catch(e => console.error(e))
}

function getAvailableLanguages(){
  return new Promise(function(resolve, reject){
    fetch(`${API_URL}getLangs?key=${YANDEX_API_KEY}&ui=en`)
    .then(response => response.json())
    .then(json => resolve(Object.keys(json.langs)))
    .catch(e => resolve(e))
  })
}

function detectLanguageFor(text){
  return new Promise(function(resolve, reject){
    let detectURL = `${API_URL}detect?key=${YANDEX_API_KEY}&text=${encodeURI(text)}`
    fetch(detectURL)
    .then(response => response.json())
    .then(json => {
      resolve(json.lang)
    })
    .catch(e => resolve(e))
  })
}

function translateText(text, sourceLanguage, targetLanguage) {
  return new Promise((resolve, reject) => {
    let translateURL = `${API_URL}translate?key=${YANDEX_API_KEY}&lang=${sourceLanguage}-${targetLanguage}&text=${encodeURI(text)}`
    fetch(translateURL)
    .then(response => response.json())
    .then(json => resolve(json.text[0]))
    .catch(e => resolve(e))
  })
}
