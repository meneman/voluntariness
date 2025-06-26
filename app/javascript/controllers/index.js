// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import RemovalsController from "controllers/removals_controller";
import color_badge_controller from "controllers/color_badge_controller";
import navbar_controller from "controllers/navbar_controller";
import home_controller from "controllers/home_controller";
import chart from "controllers/chart_controller";
import ParticleController from "controllers/particle_controller";
import spinningWheelController from "controllers/spinning_wheel_controller";

import Sortable from "@stimulus-components/sortable";


eagerLoadControllersFrom("controllers", application)


application.register("removals", RemovalsController);
application.register("color-badge", color_badge_controller);
application.register("navbar", navbar_controller);
application.register("home-controller", home_controller);
application.register("sortable", Sortable);
application.register("chart", chart);
application.register("particle", ParticleController)
aapplication.register("spinning-wheel", spinningWheelController)