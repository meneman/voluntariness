# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "removals", to: "controllers/removals_controller.js"
pin "color-badge", to: "controllers/color_badge_controller.js"
pin "navbar", to: "controllers/navbar_controller.js"
pin "home-controller", to: "controllers/home_controller.js"
