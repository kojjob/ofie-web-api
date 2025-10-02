// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-loading"

// Initialize Stimulus
const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

// Configure Turbo
Turbo.session.drive = true

// Configure Stimulus development mode
application.debug = false
window.Stimulus = application

// Import Trix and ActionText for rich text editing
import "trix"
import "@rails/actiontext"

export { application }
