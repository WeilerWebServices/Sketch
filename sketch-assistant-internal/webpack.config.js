const path = require('path')
const webpack = require('webpack')
const pkg = require('./package.json')

module.exports = {
  target: 'web',
  mode: 'production',
  entry: './index.js',
  output: {
    filename: 'sketch.js',
    path: process.cwd(),
    libraryTarget: 'var',
    library: ['_sketch', 'assistants', '@sketch-hq/sketch-assistant-internal'],
  },
}
