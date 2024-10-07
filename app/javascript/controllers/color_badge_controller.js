import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="removals"
export default class extends Controller {
  connect() {
    const color = this.element.getAttribute("data-color");
    this.element.parentNode.style.setProperty("--badge-color", color);
  }
}
