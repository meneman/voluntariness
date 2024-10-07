import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="removals"
export default class extends Controller {
  static targets = ["menu", "switchToggle"];

  connect() {
    // this.switchTheme(localStorage.getItem("isDarkMode"), this.switchToggleTarget)
    // document.body.classList.toggle("dark", !localStorage.getItem("isDarkMode"))
  }

  toggleShowMenu() {
    this.menuTarget.classList.toggle("hidden");
  }
  toggleTheme(event) {
    const isDarkmode = document.body.classList.contains("dark");
    document.body.classList.toggle("dark");

    // localStorage.setItem('isDarkMode', isDarkmode)
    this.switchThemeButton(!isDarkmode, this.switchToggleTarget);
    this.toggleThemeSession();
  }

  toggleThemeSession() {
    fetch("/toggle_theme", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document
          .querySelector('meta[name="csrf-token"]')
          .getAttribute("content"),
      },
    });
  }

  switchThemeButton(isDarkmode, switchToggle) {
    const darkIcon = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
</svg>`;

    const lightIcon = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
</svg>`;

    if (isDarkmode) {
      switchToggle.classList.remove("bg-cyan-600", "-translate-x-1");
      switchToggle.classList.add("bg-slate-800", "translate-x-full");
      setTimeout(() => {
        switchToggle.innerHTML = darkIcon;
      }, 250);
    } else {
      switchToggle.classList.add("bg-cyan-600", "-translate-x-1");
      switchToggle.classList.remove("bg-slate-800", "translate-x-full");
      setTimeout(() => {
        switchToggle.innerHTML = lightIcon;
      }, 250);
    }
  }
}
