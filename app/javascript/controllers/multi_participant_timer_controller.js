import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = { 
    timeout: { type: Number, default: 5000 },
    actionId: Number,
    taskId: Number
  }

  connect() {
    this.selectedParticipants = new Set()
    this.timerActive = false
    this.timerTimeout = null
  }

  disconnect() {
    this.clearTimer()
  }

  async participantClick(event) {
    event.preventDefault()
    const button = event.currentTarget
    const participantId = button.dataset.participantId
    
    if (!this.timerActive) {
      // First click: Create action immediately
      try {
        const actionId = await this.createAction(participantId)
        this.actionIdValue = actionId
        this.selectedParticipants.add(participantId)
        this.markButtonAsSelected(button)
        this.startTimer()
      } catch (error) {
        console.error('Failed to create action:', error)
        // Let the original form submission handle the error
        button.form.submit()
      }
    } else {
      // Additional clicks: Add to existing action
      if (this.selectedParticipants.has(participantId)) {
        // Already selected, ignore
        return
      }
      
      try {
        await this.addParticipantToAction(participantId)
        this.selectedParticipants.add(participantId)
        this.markButtonAsSelected(button)
        this.resetTimer()
      } catch (error) {
        console.error('Failed to add participant:', error)
      }
    }
  }

  async createAction(participantId) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    const formData = new FormData()
    formData.append('data[task_id]', this.taskIdValue)
    formData.append('data[participant_id]', participantId)
    
    const response = await fetch('/actions', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })
    
    if (!response.ok) {
      throw new Error('Failed to create action')
    }
    
    // Process the turbo stream response
    const responseText = await response.text()
    Turbo.renderStreamMessage(responseText)
    
    // Extract action ID from the turbo stream response
    const actionIdMatch = responseText.match(/data-action-id="(\d+)"/)
    if (actionIdMatch) {
      return parseInt(actionIdMatch[1])
    }
    
    throw new Error('Could not extract action ID from response')
  }

  async addParticipantToAction(participantId) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    const formData = new FormData()
    formData.append('participant_id', participantId)
    
    const response = await fetch(`/actions/${this.actionIdValue}/add_participant`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
      },
      body: formData
    })
    
    if (!response.ok) {
      throw new Error('Failed to add participant')
    }
    
    // Process the turbo stream response
    const responseText = await response.text()
    Turbo.renderStreamMessage(responseText)
  }

  startTimer() {
    this.timerActive = true
    this.scheduleTimerEnd()
  }

  scheduleTimerEnd() {
    this.timerTimeout = setTimeout(() => {
      this.endTimer()
    }, this.timeoutValue)
  }

  resetTimer() {
    this.clearTimer()
    this.scheduleTimerEnd()
  }

  clearTimer() {
    if (this.timerTimeout) {
      clearTimeout(this.timerTimeout)
      this.timerTimeout = null
    }
  }

  endTimer() {
    this.timerActive = false
    this.clearTimer()
    this.resetButtonStates()
    this.selectedParticipants.clear()
  }

  markButtonAsSelected(button) {
    button.classList.add('selected')
    button.disabled = true
  }

  resetButtonStates() {
    this.buttonTargets.forEach(button => {
      button.classList.remove('selected')
      button.disabled = false
    })
  }
}