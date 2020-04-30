const path = require('path');
const R = require('ramda');
const webpack = require('webpack'); // eslint-disable-line import/no-unresolved
const service = require('./service');

/**
 * Sets webpack entry
 * @param {array} entries Entries defined in Webpack config
 * @param {object} fn Serverless function object
 * @param {string} servicePath Serverless service path
 * @param {boolean} useTypeScript Use .ts extension
 * @returns {object} Webpack configuration
 */
const setEntry = (entries = [], fn, servicePath, useTypeScript) => {
  if (typeof entries === 'string') {
    entries = [entries];
  }

  return R.assoc(
    'entry',
    R.objOf(
      service.fnPath('.js')(fn),
      [...entries, path.join(servicePath, service.fnPath(useTypeScript ? '.ts' : '.js')(fn))]
    )
  );
};

/**
 * Sets webpack output in configuration
 * @param {object} defaultOutput Webpack default output object
 * @param {string} outputPath Webpack output path
 * @returns {object} Webpack configuration
 */
const setOutput = (defaultOutput, outputPath) =>
  R.assoc(
    'output',
    R.merge(
      defaultOutput,
      { path: outputPath }
    )
  );

/**
 * Creates an array of webpack configurations
 * @param {object} fns Serverless functions object
 * @param {object} config Webpack config
 * @param {string} servicePath Serverless service path
 * @param {object} defaultOutput Webpack default output object
 * @param {string} folder Webpack output folder
 * @param {boolean} useTypeScript Use .ts extension
 * @returns {array} Array of webpack configurations
 */
const createConfigs = (fns, config, servicePath, defaultOutput, folder, useTypeScript) =>
  R.map(
    fn =>
      R.pipe(
        setEntry(config.entry, fn, servicePath, useTypeScript),
        setOutput(defaultOutput, path.join(servicePath, folder))
      )(config),
    R.values(fns)
  );

/**
 * Runs webpack with an array of configurations
 * @param {array} configs Array of webpack configurations
 * @returns {Promise} Webpack stats
 */
const run = configs =>
  new Promise((resolve, reject) => {
    webpack(configs, (err, stats) => {
      if (err) reject(new Error(`Webpack compilation error: ${err}`));

      console.log(stats.toString({ // eslint-disable-line no-console
        colors: true,
        hash: false,
        chunks: false,
        version: false,
      }));

      if (stats.hasErrors()) reject(new Error('Webpack compilation error, see stats above'));

      resolve(stats);
    });
  });

/**
 * Runs webpack with an array of configurations in series
 * @param {array} configs Array of webpack configurations
 * @returns {Promise} Webpack stats
 */
const runSeries = configs =>
  new Promise((resolve, reject) => {
    configs
      .map(config => () => {
        console.log(`Creating: ${Object.keys(config.entry)[0]}`); // eslint-disable-line no-console
        return run(config);
      })
      .reduce((promise, func) =>
        promise.then(() => func().then()), Promise.resolve([]))
      .then(resolve).catch(reject);
  });

module.exports = {
  createConfigs,
  run,
  runSeries,
};
