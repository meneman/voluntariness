import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['innerWheel', 'spinButton', 'textOutput', 'section'];

  // Data attributes for configuration
  static values = {
    initialDegree: { type: Number, default: 1800 }, // Default degree for spinning (5 full rotations)
    items: { type: Array, default: [] }, // Array of winning items
    targetAngle: { type: Number, default: 0 }, // Target angle from backend
    winningItem: { type: Object, default: {} }, // Winning item from backend
  };

  initialize() {
    this.clicks = 0;
    this.setupSectionMapping();
  }

  connect() {
  }

  /**
   * Sets up the mapping between wheel sections and winning items
   */
  setupSectionMapping() {
    const numSections = this.sectionTargets.length;
    const degreesPerSection = 360 / numSections;
    
    this.sectionMapping = [];
    
    // Get items from data attribute or use default items
    const items = this.itemsValue.length > 0 ? this.itemsValue : this.getDefaultItems();
    
    this.sectionTargets.forEach((section, index) => {
      // Calculate the angle range for this section
      const startAngle = index * degreesPerSection;
      const endAngle = (index + 1) * degreesPerSection;
      const centerAngle = startAngle + (degreesPerSection / 2);
      
      // Map section to item (cycle through items if more sections than items)
      const itemIndex = index % items.length;
      const item = items[itemIndex];
      
      this.sectionMapping.push({
        index: index,
        element: section,
        startAngle: startAngle,
        endAngle: endAngle,
        centerAngle: centerAngle,
        item: item
      });
      
      // Store item data on the section element for debugging
      section.dataset.itemName = item.name;
      section.dataset.sectionIndex = index;
    });
    
  }

  /**
   * Default items if none provided via data attribute
   */
  getDefaultItems() {
    return [
      { name: 'Magic Wand', svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M4 4l12 12-1.5 1.5L2.5 5.5 4 4zm16.5 11.5L18 18l-12-12 1.5-1.5L20.5 15.5z"/></svg>' },
      { name: 'Shield', svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2L2 7l10 15 10-15-10-5z"/></svg>' },
      { name: 'Crown', svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M5 16L3 10l5.5 5L12 4l3.5 11L21 10l-2 6H5z"/></svg>' },
      { name: 'Gem', svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M6 3h12l4 6-10 13L2 9z"/></svg>' },
      { name: 'Potion', svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 2v4H7v2h2v2l-4 8h12l-4-8V8h2V6h-2V2H9z"/></svg>' },
      { name: 'Star Badge', svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>' }
    ];
  }

  /**
   * Gets the winning item from backend data
   */
  getWinningItem() {
    if (this.winningItemValue && Object.keys(this.winningItemValue).length > 0) {
      return this.winningItemValue;
    }
    
    // Fallback to random selection if no backend data
    const items = this.itemsValue.length > 0 ? this.itemsValue : this.getDefaultItems();
    const randomIndex = Math.floor(Math.random() * items.length);
    return items[randomIndex];
  }

  /**
   * Gets the target angle from backend or calculates fallback
   */
  getTargetAngle() {
    if (this.targetAngleValue !== 0) {
      return this.targetAngleValue;
    }
    
    // Fallback calculation if no backend angle
    const winningItem = this.getWinningItem();
    const targetSection = this.sectionMapping.find(section => 
      section.item.name === winningItem.name
    );
    
    return targetSection ? targetSection.centerAngle : this.sectionMapping[0].centerAngle;
  }

  /**
   * Handles the spin button click event.
   */
  spin() {
    this.clicks++;

    // Get the winning item and target angle from backend
    const winningItem = this.getWinningItem();
    const targetAngle = this.getTargetAngle();
    
    
    // Calculate base rotations (multiple full spins for effect)
    const baseRotations = this.initialDegreeValue;
    
    // Add small random offset within the target section for visual variety
    const sectionSize = 360 / this.sectionMapping.length;
    const randomOffset = (Math.random() - 0.5) * (sectionSize * 0.6); // ±30% of section size
    
    // Calculate total rotation to land on target
    const totalDegree = baseRotations + targetAngle + randomOffset;


    // Apply the rotation to the inner wheel
    this.innerWheelTarget.style.transform = `rotate(${totalDegree}deg)`;
    this.innerWheelTarget.style.transition = 'transform 4s cubic-bezier(0.23, 1, 0.32, 1)';

    // Disable the spin button during animation
    this.spinButtonTarget.disabled = true;
    this.spinButtonTarget.style.pointerEvents = 'none';

    // Add spinning visual effects
    this.addSpinningEffects();

    // Dispatch completion event after wheel stops
    setTimeout(() => {
      // Re-enable spin button
      this.spinButtonTarget.disabled = false;
      this.spinButtonTarget.style.pointerEvents = 'auto';
      
      // Dispatch completion event with pre-determined winning item
      document.dispatchEvent(new CustomEvent('gamble:wheel-complete', {
        detail: { 
          totalDegree: totalDegree,
          winningItem: winningItem,
          controller: this 
        }
      }));
    }, 4500); // Match the CSS transition duration + small buffer
  }

  /**
   * Adds visual effects during spinning
   */
  addSpinningEffects() {
    // Add spinning class for visual effects
    this.element.classList.add('spinning');
    
    // Remove spinning class after animation
    setTimeout(() => {
      this.element.classList.remove('spinning');
    }, 4000);
  }
}