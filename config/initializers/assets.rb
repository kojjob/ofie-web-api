# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# Add node_modules to asset paths for packages
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Precompile additional assets for production
Rails.application.config.assets.precompile += %w[
  application.css
  navbar_enhancement.css
  z-index.css
  properties/gallery.css
  properties/show.css
]