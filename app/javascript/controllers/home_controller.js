import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="removals"
export default class extends Controller {

  static values = {
    editMode: Boolean 
  }

  static targets = ["task", "sortable"]


  toggleEditMode (e) {
    this.editModeValue = !this.editModeValue
    this.element.classList.toggle("edit-mode", this.editModeValue)
    e.currentTarget.classList.toggle("bg-blue-600", this.editModeValue)

  }

}
