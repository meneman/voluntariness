import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['pointsDisplay', 'betButton', 'statusMessage', 'spinButton', 'badgeDisplay'];
  
  static values = {
    userPoints: { type: Number, default: 100 }, // Mock starting points
    betAmount: { type: Number, default: 1 },
    isSpinning: { type: Boolean, default: false }
  };

  connect() {
    this.updatePointsDisplay();
    this.updateBetButton();
    this.showWelcomeMessage();
  }

  /**
   * Handle betting - deduct points and enable spinning
   */
  placeBet() {
    if (this.isSpinningValue) {
      this.showMessage("Please wait for the current spin to complete!", "warning");
      return;
    }

    if (this.userPointsValue < this.betAmountValue) {
      this.showMessage("Not enough points to place bet!", "error");
      return;
    }

    // Deduct bet amount
    this.userPointsValue -= this.betAmountValue;
    this.updatePointsDisplay();
    
    // Enable spinning and update UI
    this.isSpinningValue = true;
    this.updateBetButton();
    this.enableSpinButton();
    
    this.showMessage(`Bet placed! ${this.betAmountValue} point(s) deducted. Click the wheel to spin!`, "success");
  }

  /**
   * Handle spin completion (called by spinning wheel controller)
   */
  onSpinComplete(event) {
    if (!this.isSpinningValue) return;

    // Reset spinning state
    this.isSpinningValue = false;
    this.updateBetButton();
    this.disableSpinButton();

    // Determine reward based on spin result
    const reward = this.calculateReward();
    this.awardReward(reward);
  }

  /**
   * Calculate reward based on random outcome
   */
  calculateReward() {
    const random = Math.random();
    
    if (random < 0.1) { // 10% chance
      return { type: 'jackpot', points: 10, badge: 'gold' };
    } else if (random < 0.3) { // 20% chance  
      return { type: 'big_win', points: 5, badge: 'silver' };
    } else if (random < 0.6) { // 30% chance
      return { type: 'small_win', points: 2, badge: 'bronze' };
    } else if (random < 0.8) { // 20% chance
      return { type: 'break_even', points: 1, badge: null };
    } else { // 20% chance
      return { type: 'lose', points: 0, badge: null };
    }
  }

  /**
   * Award the calculated reward
   */
  awardReward(reward) {
    this.userPointsValue += reward.points;
    this.updatePointsDisplay();

    if (reward.badge) {
      this.awardBadge(reward.badge);
    }

    let message = "";
    switch (reward.type) {
      case 'jackpot':
        message = `🎉 JACKPOT! You won ${reward.points} points and a ${reward.badge} badge!`;
        break;
      case 'big_win':
        message = `🎊 Big Win! You won ${reward.points} points and a ${reward.badge} badge!`;
        break;
      case 'small_win':
        message = `✨ Nice! You won ${reward.points} points and a ${reward.badge} badge!`;
        break;
      case 'break_even':
        message = `😐 Break even! You got your ${reward.points} point back.`;
        break;
      case 'lose':
        message = `😞 Better luck next time! You lost your bet.`;
        break;
    }

    this.showMessage(message, reward.type === 'lose' ? 'error' : 'success');
  }

  /**
   * Award a badge to the user
   */
  awardBadge(badgeType) {
    if (this.hasBadgeDisplayTarget) {
      const badgeElement = document.createElement('div');
      badgeElement.className = `badge badge-${badgeType} animate-bounce`;
      badgeElement.innerHTML = this.getBadgeHTML(badgeType);
      
      this.badgeDisplayTarget.appendChild(badgeElement);
      

    }
  }

  /**
   * Get HTML for different badge types
   */
  getBadgeHTML(badgeType) {
    const badges = {
      gold: '🏆 Gold Badge',
      silver: '🥈 Silver Badge', 
      bronze: '🥉 Bronze Badge'
    };
    return badges[badgeType] || '🏅 Badge';
  }

  /**
   * Enable the spin button
   */
  enableSpinButton() {
    if (this.hasSpinButtonTarget) {
      this.spinButtonTarget.classList.remove('disabled');
      this.spinButtonTarget.style.pointerEvents = 'auto';
      this.spinButtonTarget.style.opacity = '1';
    }
  }

  /**
   * Disable the spin button
   */
  disableSpinButton() {
    if (this.hasSpinButtonTarget) {
      this.spinButtonTarget.classList.add('disabled');
      this.spinButtonTarget.style.pointerEvents = 'none';
      this.spinButtonTarget.style.opacity = '0.5';
    }
  }

  /**
   * Update points display
   */
  updatePointsDisplay() {
    if (this.hasPointsDisplayTarget) {
      this.pointsDisplayTarget.textContent = this.userPointsValue;
    }
  }

  /**
   * Update bet button state
   */
  updateBetButton() {
    if (this.hasBetButtonTarget) {
      const canBet = !this.isSpinningValue && this.userPointsValue >= this.betAmountValue;
      this.betButtonTarget.disabled = !canBet;
      this.betButtonTarget.classList.toggle('opacity-50', !canBet);
      
      if (this.isSpinningValue) {
        this.betButtonTarget.textContent = "Spinning...";
      } else {
        this.betButtonTarget.textContent = `Bet ${this.betAmountValue} Point${this.betAmountValue !== 1 ? 's' : ''}`;
      }
    }
  }

  /**
   * Show status message
   */
  showMessage(text, type = 'info') {
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.textContent = text;
      this.statusMessageTarget.className = `status-message ${type}`;
      
      // Auto-clear message after 5 seconds
      setTimeout(() => {
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = '';
          this.statusMessageTarget.className = 'status-message';
        }
      }, 5000);
    }
  }

  /**
   * Show welcome message
   */
  showWelcomeMessage() {
    this.showMessage("Welcome to the Wheel of Fortune! Place a bet to start spinning.", "info");
  }

  /**
   * Reset game state (for testing)
   */
  reset() {
    this.userPointsValue = 100;
    this.isSpinningValue = false;
    this.updatePointsDisplay();
    this.updateBetButton();
    this.disableSpinButton();
    this.showWelcomeMessage();
  }
}