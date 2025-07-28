const { environment } = require('@rails/webpacker')

// Bootstrap 5 の設定
const webpack = require('webpack')
environment.plugins.prepend('Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Popper: ['@popperjs/core', 'default']
  })
)

module.exports = environment
