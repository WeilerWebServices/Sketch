module.exports = [
  require('@sketch-hq/sketch-assistant-core-rules'),
  async () => ({
    name: '@sketch-hq/sketch-assistant-internal',
    rules: [],
    config: { rules: require('./config.json') }
  })
]
