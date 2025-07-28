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

// CSSとSassの処理を有効化
const sassLoader = environment.loaders.get('sass')
sassLoader.use = sassLoader.use.map(loader => {
  if (loader.loader === 'sass-loader') {
    return {
      ...loader,
      options: {
        ...loader.options,
        implementation: require('sass')
      }
    }
  }
  return loader
})

module.exports = environment
