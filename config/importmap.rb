# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"
pin_all_from "app/javascript/mixins", under: "mixins"
pin "@hotwired/turbo-rails", to: "turbo.min.js"

# Explicitly pin navigation controllers
pin "controllers/dropdown_controller", to: "controllers/dropdown_controller.js"
pin "controllers/notifications_controller", to: "controllers/notifications_controller.js"
pin "controllers/mobile_menu_controller", to: "controllers/mobile_menu_controller.js"
pin "controllers/mobile_search_controller", to: "controllers/mobile_search_controller.js"
