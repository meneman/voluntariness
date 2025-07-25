import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["participantGrid", "spinningWheel", "celebration"]

  connect() {
    // Add document-level event listener for wheel completion
    this.wheelCompleteHandler = this.handleWheelComplete.bind(this)
    document.addEventListener('gamble:wheel-complete', this.wheelCompleteHandler)
  }

  disconnect() {
    // Clean up event listener
    document.removeEventListener('gamble:wheel-complete', this.wheelCompleteHandler)
  }

  handleWheelComplete(event) {
    // Extract participant ID from the spinning section
    const participantElements = document.querySelectorAll('[data-participant-id]')
    let participantId = null
    
    // Try to find participant ID from form elements or data attributes
    participantElements.forEach(element => {
      if (element.value || element.dataset.participantId) {
        participantId = element.value || element.dataset.participantId
      }
    })
    
    // Fallback: look for participant ID in the URL or hidden fields
    if (!participantId) {
      const hiddenFields = document.querySelectorAll('input[name="participant_id"]')
      if (hiddenFields.length > 0) {
        participantId = hiddenFields[0].value
      }
    }
    
    if (participantId) {
      
      // Use fetch with proper Turbo Stream handling
      fetch('/gamble/result', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html',
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: new URLSearchParams({
          participant_id: participantId
        })
      }).then(response => {
        if (response.ok) {
          return response.text()
        }
        throw new Error('Network response was not ok')
      }).then(html => {
        // Manually process the Turbo Stream response
        if (window.Turbo && window.Turbo.renderStreamMessage) {
          window.Turbo.renderStreamMessage(html)
        } else {
          // Fallback: parse and apply streams manually
          const parser = new DOMParser()
          const doc = parser.parseFromString(html, 'text/html')
          const streams = doc.querySelectorAll('turbo-stream')
          
          streams.forEach(stream => {
            const action = stream.getAttribute('action')
            const target = stream.getAttribute('target')
            const template = stream.querySelector('template')
            
            if (action === 'update' && target && template) {
              const targetElement = document.getElementById(target)
              if (targetElement) {
                targetElement.innerHTML = template.innerHTML
              }
            }
          })
        }
      }).catch(error => {
        // Error handling for result advancement
      })
    } else {
      // Could not find participant ID to advance to results
    }
  }

  selectParticipant(event) {
    // Add visual feedback for participant selection
    const participantCards = this.participantGridTarget.querySelectorAll('.participant-card')
    participantCards.forEach(card => card.classList.remove('selected'))
    
    const selectedCard = event.target.closest('.participant-card')
    if (selectedCard) {
      selectedCard.classList.add('selected')
    }
  }

  placeBet(event) {
    // Find the submit button in the form
    const submitButton = event.target.querySelector('input[type="submit"], button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = true
      submitButton.value = "Spinning..."
    }
    
    // Add visual feedback
    this.addSpinningAnimation()
    
    // Allow the form to submit
  }

  addSpinningAnimation() {
    // If we have a spinning wheel target, start the animation
    if (this.hasSpinningWheelTarget) {
      this.spinningWheelTarget.classList.add('spinning')
      
      // Stop the spinning animation after 2.5 seconds (before the auto-advance)
      setTimeout(() => {
        this.spinningWheelTarget.classList.remove('spinning')
        this.spinningWheelTarget.classList.add('slowing-down')
      }, 2500)
    }
  }

  showCelebration() {
    // Add celebration animation when results are shown
    if (this.hasCelebrationTarget) {
      this.celebrationTarget.classList.add('active')
      this.createConfetti()
    }
  }

  createConfetti() {
    // Simple confetti animation
    const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#ffeaa7', '#dda0dd']
    
    for (let i = 0; i < 50; i++) {
      setTimeout(() => {
        const confetti = document.createElement('div')
        confetti.className = 'confetti-piece'
        confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)]
        confetti.style.left = Math.random() * 100 + '%'
        confetti.style.animationDelay = Math.random() * 3 + 's'
        
        if (this.hasCelebrationTarget) {
          this.celebrationTarget.appendChild(confetti)
          
          // Remove confetti after animation
          setTimeout(() => {
            if (confetti.parentNode) {
              confetti.parentNode.removeChild(confetti)
            }
          }, 3000)
        }
      }, i * 50)
    }
  }

  // Handle form submissions with better UX
  handleFormSubmit(event) {
    const form = event.target
    const submitButton = form.querySelector('input[type="submit"], button[type="submit"]')
    
    if (submitButton) {
      submitButton.disabled = true
      const originalText = submitButton.textContent
      submitButton.textContent = submitButton.dataset.disableWith || "Processing..."
      
      // Re-enable after a delay if the form doesn't redirect
      setTimeout(() => {
        submitButton.disabled = false
        submitButton.textContent = originalText
      }, 5000)
    }
  }

  // Add visual feedback for button interactions
  buttonFeedback(event) {
    const button = event.target
    button.classList.add('button-pressed')
    
    setTimeout(() => {
      button.classList.remove('button-pressed')
    }, 150)
  }

}