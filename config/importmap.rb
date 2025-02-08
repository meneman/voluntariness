# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin_all_from "app/javascript/controllers", under: "controllers", to: "controllers"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin "@stimulus-components/sortable", to: "@stimulus-components--sortable.js" # @5.0.1
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.8
pin "sortablejs" # @1.15.6
pin "stimulus-glow" # @0.3.0
pin "@stimulus-components/color-picker", to: "@stimulus-components--color-picker.js" # @2.0.0
pin "@simonwep/pickr", to: "@simonwep--pickr.js" # @1.9.0
