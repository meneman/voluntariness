import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "menuIcon", "closeIcon"]

  connect() {
    this.isOpen = false
    document.addEventListener("click", this.closeOnClickOutside)
  }

  toggleMenu() {
    this.isOpen = !this.isOpen
    this.updateMenuVisibility()
  }

  closeMenu() {
    this.isOpen = false
    this.updateMenuVisibility()
  }

  updateMenuVisibility() {
    if (this.isOpen) {
      this.mobileMenuTarget.classList.remove("hidden")
      this.menuIconTarget.classList.add("hidden")
      this.closeIconTarget.classList.remove("hidden")
    } else {
      this.mobileMenuTarget.classList.add("hidden")
      this.menuIconTarget.classList.remove("hidden")
      this.closeIconTarget.classList.add("hidden")
    }
  }

  // Close menu when clicking outside (optional enhancement)
  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }

  closeOnClickOutside = (event) => {
    if (!this.element.contains(event.target) && this.isOpen) {
      this.closeMenu()
    }
  }
}