// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

// Import controllers using importmap-rails pattern (not webpack require.context)
import "controllers"

// Import Trix and ActionText for rich text editing
import "trix"
import "@rails/actiontext"
