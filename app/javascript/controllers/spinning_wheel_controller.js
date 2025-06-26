import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['innerWheel', 'spinButton', 'textOutput', 'section'];

  // Data attributes for configuration
  static values = {
    initialDegree: { type: Number, default: 1800 }, // Default degree for spinning (e.g., 5 full rotations)
  };

  initialize() {
    this.clicks = 0;
  }

  /**
   * Handles the spin button click event.
   */
  spin() {
    this.clicks++;

    // Calculate the new degree for the wheel rotation
    const extraDegree = Math.floor(Math.random() * (360 - 1 + 1)) + 1;
    const totalDegree = this.initialDegreeValue * this.clicks + extraDegree;

    // Apply the rotation to the inner wheel
    this.innerWheelTarget.style.transform = `rotate(${totalDegree}deg)`;

    // Logic for making the spin button "tilt" when a section aligns
    this.sectionTargets.forEach((section) => {
      let c = 0;
      const n = 700; // Number of intervals for the check
      const interval = setInterval(() => {
        c++;
        if (c === n) {
          clearInterval(interval);
        }

        // Get the current top offset of the section
        const sectionOffsetTop = section.getBoundingClientRect().top;
        this.textOutputTarget.textContent = sectionOffsetTop.toFixed(2); // Display for debugging

        // If the section is close to the indicator (23.89px, adjust if needed)
        if (sectionOffsetTop < 23.89 && sectionOffsetTop > 0) {
          this.spinButtonTarget.classList.add('spin-animation');
          setTimeout(() => {
            this.spinButtonTarget.classList.remove('spin-animation');
          }, 100);
        }
      }, 10);
    });

    // Dispatch completion event after wheel stops spinning
    setTimeout(() => {
      this.dispatch('complete', { detail: { totalDegree } });
    }, 7000); // Adjust timing to match wheel animation duration
  }
}