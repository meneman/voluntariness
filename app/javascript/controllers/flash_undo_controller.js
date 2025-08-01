import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]
  static values = { 
    duration: { type: Number, default: 800 },
    breakDelay: { type: Number, default: 100 },
    deleteUrl: String,
    autoRemoveDelay: { type: Number, default: 5000 }
  }

  connect() {
    // Ensure card starts with proper positioning
    if (this.hasCardTarget) {
      this.cardTarget.style.position = "relative"
      this.cardTarget.style.transformOrigin = "center center"
    }
    
    // Set up auto-removal timer (like the original removals controller)
    this.autoRemoveTimer = setTimeout(() => {
      this.autoRemove()
    }, this.autoRemoveDelayValue)
  }

  disconnect() {
    // Clear the timer if controller is disconnected
    if (this.autoRemoveTimer) {
      clearTimeout(this.autoRemoveTimer)
    }
  }

  autoRemove() {
    // Smoothly fade out and remove (without animation)
    this.element.style.transition = "opacity 0.5s ease-out, transform 0.5s ease-out"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-20px)"
    
    setTimeout(() => {
      this.removeFromDOM()
    }, 500)
  }

  // Called when undo button is clicked
  triggerBreakAndFall(event) {
    // Prevent any default behavior
    event.preventDefault()
    
    // Cancel auto-removal since user is manually undoing
    if (this.autoRemoveTimer) {
      clearTimeout(this.autoRemoveTimer)
      this.autoRemoveTimer = null
    }
    
    // Get the delete URL from the button
    const deleteUrl = event.target.closest('[data-flash-undo-delete-url-value]')
                              ?.getAttribute('data-flash-undo-delete-url-value')
    
    if (deleteUrl) {
      this.deleteUrlValue = deleteUrl
    }
    
    this.animateBreakAndFall()
  }

  animateBreakAndFall() {
    const card = this.cardTarget
    
    // Disable pointer events during animation
    card.style.pointerEvents = "none"
    
    // Modern smooth fade-out animation
    this.animateModernExit().then(() => {
      this.removeCard()
    })
  }

  animateModernExit() {
    return new Promise((resolve) => {
      const card = this.cardTarget
      
      // Simple fall animation with rotation
      const exitAnimation = card.animate([
        {
          transform: "translateY(0) rotate(0deg)",
          opacity: 1
        },
        {
          transform: "translateY(100vh) rotate(-12deg)",
          opacity: 0
        }
      ], {
        duration: 800,
        easing: "cubic-bezier(0.55, 0.085, 0.68, 0.53)", // Ease-in-quad for gravity feel
        fill: "forwards"
      })

      exitAnimation.addEventListener("finish", () => resolve())
    })
  }

  removeCard() {
    // First, send the delete request to the server
    if (this.deleteUrlValue) {
      fetch(this.deleteUrlValue, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content'),
          'Accept': 'text/vnd.turbo-stream.html'
        }
      }).then(() => {
        // After successful deletion, remove the DOM element
        this.removeFromDOM()
      }).catch((error) => {
        console.error('Error deleting action:', error)
        // Still remove from DOM even if server request fails
        this.removeFromDOM()
      })
    } else {
      // If no delete URL, just remove from DOM
      this.removeFromDOM()
    }
  }

  removeFromDOM() {
    // Remove the entire flash message container
    const flashContainer = this.element.closest('.flash__message')
    if (flashContainer) {
      flashContainer.remove()
    } else {
      this.element.remove()
    }
  }

}