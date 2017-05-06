# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'
Rails.application.config.assets.precompile += %w( distribbox.js )
Rails.application.config.assets.precompile += %w( Piano-Keyboard.js )
Rails.application.config.assets.precompile += %w( demo.js )
Rails.application.config.assets.precompile += %w( Piano-Keyboard.css )

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
