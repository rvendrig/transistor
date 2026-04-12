const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Handle path aliases
config.resolver.extraNodeModules = {
  '@': __dirname + '/src',
};

module.exports = config;
