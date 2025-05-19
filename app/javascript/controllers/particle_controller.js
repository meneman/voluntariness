import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    count: { type: Number, default: 10 },
    colors: { type: Array, default: ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff"] },
    duration: { type: Number, default: 3000 },
    gravity: { type: Number, default: 4 },
    initialSpeed: { type: Number, default: 3 }
  }
  
  connect() {
    // Initialize any setup needed when controller connects
  }
  
  spawn(event) {
    const rect = this.element.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2
    
    // Create container for particles if it doesn't exist
    if (!this.particleContainer) {
      this.particleContainer = document.createElement('div')
      this.particleContainer.style.position = 'fixed'
      this.particleContainer.style.zIndex = '1000'
      this.particleContainer.style.pointerEvents = 'none'
      document.body.appendChild(this.particleContainer)
    }
    
    // Generate particles
    for (let i = 0; i < this.countValue; i++) {
      setTimeout(() => {
        // Get a random position on the border of the element
        const position = this.getRandomBorderPosition(rect)
        
        // Calculate direction vector from center of element to particle position
        const dirX = position.x - centerX
        const dirY = position.y - centerY
        
        // Normalize the direction vector
        const length = Math.sqrt(dirX * dirX + dirY * dirY)
        const normalizedDirX = dirX / length
        const normalizedDirY = dirY / length
        
        this.createParticle(position.x, position.y, normalizedDirX, normalizedDirY)
      }, Math.random() * 200) // Stagger particle creation for a more natural effect
    }
  }
  
  getRandomBorderPosition(rect) {
    // Decide which side of the rectangle to place the particle
    const side = Math.floor(Math.random() * 4) // 0: top, 1: right, 2: bottom, 3: left
    
    let x, y;
    
    switch (side) {
      case 0: // top
        x = rect.left + Math.random() * rect.width
        y = rect.top
        break
      case 1: // right
        x = rect.right
        y = rect.top + Math.random() * rect.height
        break
      case 2: // bottom
        x = rect.left + Math.random() * rect.width
        y = rect.bottom
        break
      case 3: // left
        x = rect.left
        y = rect.top + Math.random() * rect.height
        break
    }
    
    return { x, y }
  }
  
  createParticle(x, y, dirX, dirY) {
    // Create a particle element
    const particle = document.createElement('div')
    
    // Random properties for stripe-like confetti
    const width = Math.floor(Math.random() * 5) + 3 // 3-8px
    const height = Math.floor(Math.random() * 15) + 10 // 10-25px
    const colorIndex = Math.floor(Math.random() * this.colorsValue.length)
    const rotationSpeed = (Math.random() - 0.5) * 1
    
    // Initial speed with some randomness but maintaining direction away from element
    const speed = (Math.random() * 0.5 + 0.75) * this.initialSpeedValue // 75%-125% of base speed
    
    // Set particle styles for stripe appearance
    particle.style.position = 'fixed'
    particle.style.width = `${width}px`
    particle.style.height = `${height}px`
    particle.style.backgroundColor = this.colorsValue[colorIndex]
    particle.style.borderRadius = '2px' // Slightly rounded edges for stripes
    particle.style.left = `${x}px`
    particle.style.top = `${y}px`
    particle.style.pointerEvents = 'none'
    particle.style.transform = `rotate(${Math.random() * 90}deg)`
    particle.style.boxShadow = '0 0 2px rgba(0,0,0,0.1)' // Subtle shadow for depth
    
    // Add to container
    this.particleContainer.appendChild(particle)
    
    // Initial velocity components - directional based on element's center
    const vx = dirX * speed * (0.8 + Math.random() * 0.4) // Maintain direction with slight randomness
    const vy = dirY * speed * (0.8 + Math.random() * 0.4) - 2 // Add slight initial upward boost
    
    // Animation variables
    let posX = x
    let posY = y
    let rotation = 0
    let timeElapsed = 0
    let startTime = null
    let currentVx = vx
    let currentVy = vy
    
    // Get the "ground" (viewport bottom)
    const groundY = window.innerHeight
    
    // Animation function
    const animate = (timestamp) => {
      if (!startTime) startTime = timestamp
      timeElapsed = timestamp - startTime
      
      // Calculate new position with more realistic gravity
      const gravityEffect = this.gravityValue * Math.pow(timeElapsed / 1000, 1.5)
      
      // Add slight air resistance/drag
      currentVx *= 0.99
      
      posX += currentVx
      posY += currentVy + gravityEffect
      rotation += rotationSpeed
      
      // Check if particle has hit the ground
      if (posY >= groundY - height) {
        // Bounce effect with dampening
        posY = groundY - height
        currentVy = -currentVy * 0.4 // Dampen the bounce
        
        // Also slightly dampen horizontal movement on bounce
        currentVx *= 0.8
        
        // If velocity is very small, just stop bouncing
        if (Math.abs(currentVy) < 0.5) {
          currentVy = 0
        }
      } else {
        // Only update vy if not on ground
        currentVy = vy + gravityEffect
      }
      
      // Apply new position
      particle.style.left = `${posX}px`
      particle.style.top = `${posY}px`
      particle.style.transform = `rotate(${rotation}deg)`
      
      // Fade out as time passes
      const opacity = 1 - (timeElapsed / this.durationValue)
      particle.style.opacity = opacity
      
      // Continue animation until duration is reached
      if (timeElapsed < this.durationValue) {
        requestAnimationFrame(animate)
      } else {
        // Remove particle after animation completes
        if (this.particleContainer && this.particleContainer.contains(particle)) {
          this.particleContainer.removeChild(particle)
          
          // Clean up container if empty
          if (this.particleContainer.childElementCount === 0) {
            document.body.removeChild(this.particleContainer)
            this.particleContainer = null
          }
        }
      }
    }
    
    requestAnimationFrame(animate)
  }
}
