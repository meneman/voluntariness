// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application";

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
eagerLoadControllersFrom("controllers", application);

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)
import RemovalsController from "./removals_controller.js";
import color_badge_controller from "./color_badge_controller.js";
import navbar_controller from "./navbar_controller.js";
import home_controller from "./home_controller.js";
import Sortable from "@stimulus-components/sortable";

application.register("removals", RemovalsController);
application.register("color-badge", color_badge_controller);
application.register("navbar", navbar_controller);
application.register("home-controller", home_controller);

application.register("sortable", Sortable);
