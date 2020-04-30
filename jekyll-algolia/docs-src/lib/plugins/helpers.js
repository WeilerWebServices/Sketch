const highlight = require('./syntaxHighlighting.js');

// this plugin provides ATM one helper to easily compute the publicPath of assets
module.exports = function helpers(filenames, metalsmith, cb) {
  // eslint-disable-next-line no-param-reassign
  metalsmith.metadata().h = {
    highlight(src, opts) {
      const lang = opts && opts.lang;
      return highlight(src, lang);
    },
    maybeActive(navPath, singlePathOrArrayOfPaths) {
      const pathsToTest = [].concat(singlePathOrArrayOfPaths);
      return pathsToTest.some(pathToTest => navPath.indexOf(pathToTest) === 0)
        ? 'active'
        : '';
    },
  };

  cb();
};
