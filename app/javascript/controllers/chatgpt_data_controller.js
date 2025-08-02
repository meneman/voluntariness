import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "data"]
  
  connect() {
    this.isVisible = false
  }
  
  toggleData() {
    const container = this.containerTarget
    const toggleButton = document.getElementById('toggle-data-btn')
    const copyButton = document.getElementById('copy-data-btn')
    
    if (this.isVisible) {
      // Hide the data
      container.classList.add('hidden')
      copyButton.classList.add('hidden')
      toggleButton.textContent = 'Show Data'
      this.isVisible = false
    } else {
      // Show the data
      container.classList.remove('hidden')
      copyButton.classList.remove('hidden')
      toggleButton.textContent = 'Hide Data'
      this.isVisible = true
    }
  }
  
  async copyData() {
    const dataText = this.dataTarget.textContent
    
    try {
      await navigator.clipboard.writeText(dataText)
      this.showCopyFeedback()
    } catch (err) {
      // Fallback for older browsers
      this.fallbackCopyToClipboard(dataText)
    }
  }
  
  fallbackCopyToClipboard(text) {
    const textArea = document.createElement("textarea")
    textArea.value = text
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showCopyFeedback()
    } catch (err) {
      console.error('Unable to copy to clipboard:', err)
      this.showCopyError()
    } finally {
      document.body.removeChild(textArea)
    }
  }
  
  showCopyFeedback() {
    const copyButtons = document.querySelectorAll('[data-action*="chatgpt-data#copyData"]')
    
    copyButtons.forEach(button => {
      const originalText = button.textContent
      button.textContent = 'Copied!'
      button.classList.remove('bg-green-500', 'hover:bg-green-600', 'bg-gray-500', 'hover:bg-gray-600')
      button.classList.add('bg-emerald-500', 'hover:bg-emerald-600')
      
      setTimeout(() => {
        button.textContent = originalText
        if (button.classList.contains('bg-gray-500') || originalText === 'Copy') {
          button.classList.remove('bg-emerald-500', 'hover:bg-emerald-600')
          button.classList.add('bg-gray-500', 'hover:bg-gray-600')
        } else {
          button.classList.remove('bg-emerald-500', 'hover:bg-emerald-600')
          button.classList.add('bg-green-500', 'hover:bg-green-600')
        }
      }, 2000)
    })
  }
  
  showCopyError() {
    const copyButtons = document.querySelectorAll('[data-action*="chatgpt-data#copyData"]')
    
    copyButtons.forEach(button => {
      const originalText = button.textContent
      button.textContent = 'Failed to Copy'
      button.classList.add('bg-red-500', 'hover:bg-red-600')
      
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove('bg-red-500', 'hover:bg-red-600')
        if (button.classList.contains('bg-gray-500') || originalText === 'Copy') {
          button.classList.add('bg-gray-500', 'hover:bg-gray-600')
        } else {
          button.classList.add('bg-green-500', 'hover:bg-green-600')
        }
      }, 2000)
    })
  }
}