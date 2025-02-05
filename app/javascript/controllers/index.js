// Import and register all your controllers from the importmap via controllers/**/*_controller

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import RemovalsController from "./removals_controller.js";
import color_badge_controller from "./color_badge_controller.js";
import navbar_controller from "./navbar_controller.js";
import home_controller from "./home_controller.js";
// import Sortable from "@stimulus-components/sortable";
eagerLoadControllersFrom("controllers", application)


application.register("removals", RemovalsController);
application.register("color-badge", color_badge_controller);
application.register("navbar", navbar_controller);
application.register("home-controller", home_controller);

// application.register("sortable", Sortable);
