import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="removals"
export default class extends Controller {
  static targets = [
    "menu",
    "switchToggle",
    "theme",
    "darkbutton",
    "lightbutton",
  ];

  static values = {
    theme: String,
  };

  connect() {
    // lets have many themes one day :)
    // this.setTheme(this.themeValue);
    this.setTheme("dark");

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
    this.menuTarget.classList.toggle("hidden");
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
}
