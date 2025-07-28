import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { userId: Number }
  static targets = ["lightIcon", "darkIcon", "systemIcon"]
  
  connect() {
    this.initializeTheme();
    this.updateIcons();
    
    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', () => {
        if (this.getCurrentTheme() === 'system') {
          this.applyTheme('system');
        }
      });
  }
  
  initializeTheme() {
    const savedTheme = localStorage.getItem('theme');
    const serverTheme = this.element.dataset.serverTheme;
    
    // Priority: localStorage -> server -> system
    const theme = savedTheme || serverTheme || 'system';
    this.applyTheme(theme);
  }
  
  toggleTheme() {
    const currentTheme = this.getCurrentTheme();
    const themes = ['light', 'dark', 'system'];
    const currentIndex = themes.indexOf(currentTheme);
    const nextTheme = themes[(currentIndex + 1) % themes.length];
    
    this.setTheme(nextTheme);
  }
  
  setTheme(theme) {
    const previousTheme = this.getCurrentTheme();
    this.applyTheme(theme);
    this.storeTheme(theme);
    this.updateIcons();
    
    // Track theme change with PostHog (client-side for immediate feedback)
    if (typeof posthog !== 'undefined') {
      posthog.capture('theme_changed', {
        new_theme: theme,
        previous_theme: previousTheme,
        source: 'client_immediate'
      });
    }
    
    // Dispatch custom event for other controllers
    this.dispatch('changed', { detail: { theme, previousTheme } });
  }
  
  applyTheme(theme) {
    const html = document.documentElement;
    
    // Remove existing theme classes
    html.classList.remove('dark', 'light');
    
    if (theme === 'dark') {
      html.classList.add('dark');
    } else if (theme === 'light') {
      html.classList.add('light');
    } else if (theme === 'system') {
      // Apply system preference
      if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        html.classList.add('dark');
      }
    }
    
    // Store current theme as data attribute
    html.dataset.theme = theme;
  }
  
  storeTheme(theme) {
    localStorage.setItem('theme', theme);
    
    // Sync with server if user is logged in
    if (this.hasUserIdValue) {
      this.updateServerTheme(theme);
    }
  }
  
  async updateServerTheme(theme) {
    try {
      await fetch('/api/theme', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ theme: theme })
      });
    } catch (error) {
      console.warn('Failed to sync theme with server:', error);
    }
  }
  
  getCurrentTheme() {
    return document.documentElement.dataset.theme || 'system';
  }
  
  updateIcons() {
    const theme = this.getCurrentTheme();
    
    // Hide all icons first
    if (this.hasLightIconTarget) this.lightIconTarget.classList.add('hidden');
    if (this.hasDarkIconTarget) this.darkIconTarget.classList.add('hidden');
    if (this.hasSystemIconTarget) this.systemIconTarget.classList.add('hidden');
    
    // Show appropriate icon
    if (theme === 'light' && this.hasLightIconTarget) {
      this.lightIconTarget.classList.remove('hidden');
    } else if (theme === 'dark' && this.hasDarkIconTarget) {
      this.darkIconTarget.classList.remove('hidden');
    } else if (this.hasSystemIconTarget) {
      this.systemIconTarget.classList.remove('hidden');
    }
  }
}