import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="date-range-submit"
export default class extends Controller {
  static targets = ["startDate", "endDate"]

  checkAndSubmit() {
    // Check if both date fields have values
    const startDate = this.startDateTarget.value
    const endDate = this.endDateTarget.value
    
    if (startDate && endDate) {
      // Submit the form
      this.element.submit()
    }
  }
}