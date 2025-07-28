import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="posthog"
export default class extends Controller {
  static values = { 
    event: String,
    properties: Object 
  }

  connect() {
    // Client-side controller for immediate user interactions
    // Page views are tracked server-side
  }

  // Track custom events
  track(event) {
    event.preventDefault()
    
    if (typeof posthog === 'undefined') {
      console.log('PostHog not loaded, skipping event:', this.eventValue)
      return
    }

    const eventName = this.eventValue || event.currentTarget.dataset.posthogEvent
    const properties = this.propertiesValue || {}
    
    // Add some default properties
    const enrichedProperties = {
      ...properties,
      source: 'web_app',
      page: window.location.pathname,
      timestamp: new Date().toISOString()
    }

    posthog.capture(eventName, enrichedProperties)
    console.log('PostHog event tracked:', eventName, enrichedProperties)
  }

  // Note: Page views are tracked server-side automatically
  // This method kept for backwards compatibility but not used

  // Client-side tracking only for immediate UI feedback
  // Most events are tracked server-side for reliability
  
  // Track theme changes (client-side because it's immediate UI feedback)
  trackThemeChange(newTheme, previousTheme) {
    this.trackEvent('theme_changed', {
      new_theme: newTheme,
      previous_theme: previousTheme,
      source: 'client_immediate'
    })
  }

  // Generic event tracking method
  trackEvent(eventName, properties = {}) {
    if (typeof posthog === 'undefined') {
      console.log('PostHog not loaded, skipping event:', eventName)
      return
    }

    const enrichedProperties = {
      ...properties,
      page: window.location.pathname,
      timestamp: new Date().toISOString()
    }

    posthog.capture(eventName, enrichedProperties)
    console.log('PostHog event tracked:', eventName, enrichedProperties)
  }
}