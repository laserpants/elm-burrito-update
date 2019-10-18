var path = require('path');
var webpack = require('webpack');

module.exports = function() {

  var keys = {};

  return {
    mode: 'development',
    entry: './index.js',
    output: {
      path: __dirname + '/dist',
      filename: 'main.js'
    },
    module: {
      rules: [
        {
          test: /\.html$/,
          exclude: /node_modules/,
          loader: 'file-loader?name=[name].[ext]'
        },
        {
          test: /\.elm$/,
          exclude: [ /elm-stuff/, /node_modules/ ],
          loader: 'elm-webpack-loader?verbose=true&warn=true',
          options: {
            debug: false
          }
        }
      ]
    },
    devServer: {
      inline: true,
      stats: 'errors-only',
      historyApiFallback: {
        index: 'index.html'
      }
    },
    plugins: [
      new webpack.DefinePlugin(keys)
    ]
  };

};
