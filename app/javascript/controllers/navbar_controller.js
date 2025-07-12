import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="navbar"
export default class extends Controller {
  static targets = [
    "menu",
    "menuIcon",
    "closeIcon",
    "switchToggle",
    "theme",
    "darkbutton",
    "lightbutton",
    "navLink",
  ];

  static values = {
    theme: String,
  };

  connect() {
    // lets have many themes one day :)
    // this.setTheme(this.themeValue);
    this.setTheme("dark");
    this.isMenuOpen = false;
    
    // Set up navigation event listeners
    this.setupNavigationListeners();
    
    // Set initial active state
    this.updateActiveNavLink();
  }

  setTheme(target) {
    document.body.classList.remove("light", "dark");
    document.body.classList.add(target);
    // changing theme makes all cached pages useless
  }

  setDarkTheme() {
   //this.lightbuttonTarget.classList.remove("hidden");
    this.darkbuttonTarget.classList.add("hidden");
    this.setTheme("dark");
    this.toggleThemeSession("dark");
  }
  
  setLightTheme() {
    //this.lightbuttonTarget.classList.add("hidden");
    this.darkbuttonTarget.classList.remove("hidden");
    this.setTheme("light");
    this.toggleThemeSession("light");
  }
  
  toggleShowMenu() {
    this.isMenuOpen = !this.isMenuOpen;
    
    // Toggle menu visibility with animation
    if (this.isMenuOpen) {
      this.menuTarget.classList.remove("hidden");
      // Add a small delay to allow the element to render before animating
      setTimeout(() => {
        this.menuTarget.classList.add("animate-slideDown");
      }, 10);
    } else {
      this.menuTarget.classList.remove("animate-slideDown");
      setTimeout(() => {
        this.menuTarget.classList.add("hidden");
      }, 200);
    }
    
    // Toggle icons
    if (this.hasMenuIconTarget && this.hasCloseIconTarget) {
      if (this.isMenuOpen) {
        this.menuIconTarget.classList.add("hidden");
        this.closeIconTarget.classList.remove("hidden");
      } else {
        this.menuIconTarget.classList.remove("hidden");
        this.closeIconTarget.classList.add("hidden");
      }
    }
  }

  toggleThemeSession(theme) {
    fetch("/toggle_theme", {
      method: "POST",
      body: JSON.stringify({ theme }),
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document
          .querySelector('meta[name="csrf-token"]')
          .getAttribute("content"),
      },
    });
  }

  setupNavigationListeners() {
    // Listen for Turbo navigation events
    document.addEventListener('turbo:load', this.updateActiveNavLink.bind(this));
    document.addEventListener('turbo:before-visit', this.handleNavigation.bind(this));
  }

  handleNavigation(_event) {
    // Optionally handle any pre-navigation logic here
    // The active state will be updated after navigation completes
  }

  updateActiveNavLink() {
    const currentPath = window.location.pathname;
    
    // Define active classes
    const activeClasses = 'bg-indigo-100 dark:bg-indigo-900/50 text-indigo-700 dark:text-indigo-300';
    const inactiveClasses = 'text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800';
    
    // Update all nav links
    this.navLinkTargets.forEach(link => {
      const linkPath = link.getAttribute('href');
      
      // Remove all classes first
      link.classList.remove(...activeClasses.split(' '), ...inactiveClasses.split(' '));
      
      // Add appropriate classes based on current path
      if (currentPath === linkPath) {
        link.classList.add(...activeClasses.split(' '));
      } else {
        link.classList.add(...inactiveClasses.split(' '));
      }
    });
  }

  // Close menu when clicking outside (optional enhancement)
  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick);
    document.removeEventListener('turbo:load', this.updateActiveNavLink);
    document.removeEventListener('turbo:before-visit', this.handleNavigation);
  }

  handleOutsideClick = (event) => {
    if (this.isMenuOpen && !this.element.contains(event.target)) {
      this.toggleShowMenu();
    }
  }
}
