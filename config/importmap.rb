# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"
pin_all_from "app/javascript/mixins", under: "mixins"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
