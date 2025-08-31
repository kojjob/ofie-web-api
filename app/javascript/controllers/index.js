// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Load all controllers
eagerLoadControllersFrom("controllers", application)

// Explicitly import key navigation controllers to ensure they're loaded
import DropdownController from "./dropdown_controller"
import NotificationsController from "./notifications_controller"
import MobileMenuController from "./mobile_menu_controller"
import MobileSearchController from "./mobile_search_controller"

// Register the controllers
application.register("dropdown", DropdownController)
application.register("notifications", NotificationsController)
application.register("mobile-menu", MobileMenuController)
application.register("mobile-search", MobileSearchController)
