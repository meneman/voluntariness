import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="removals"
export default class extends Controller {
  static targets = [ "menu"]
  
  toggleShowMenu () {  
    this.menuTarget.classList.toggle("hidden") 
  } 
}
