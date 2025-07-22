# Application constants
module VoluntarinessConstants
  # Theme settings
  DEFAULT_THEME = 'dark'.freeze
  
  # Bonus points calculation
  OVERDUE_BONUS_MULTIPLIER = 0.2
  STREAK_BONUS_POINTS = 1
  
  # User settings defaults
  MIN_STREAK_THRESHOLD = 2
  DEFAULT_STREAK_THRESHOLD = 5
  STREAK_BONI_DAYS_THRESHOLD = 5
  
  # Action scope defaults
  STREAK_CALCULATION_DAYS = 10
  
  # Default tasks configuration
  DEFAULT_TASKS_CONFIG_PATH = Rails.root.join("config", "default_tasks.yml").freeze
  
  # Obtainable useable items
  OBTAINABLE_ITEMS = [
    {
      name: 'Magic Wand',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M4 4l12 12-1.5 1.5L2.5 5.5 4 4zm16.5 11.5L18 18l-12-12 1.5-1.5L20.5 15.5z"/></svg>'
    },
    {
      name: 'Shield',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2L2 7l10 15 10-15-10-5z"/></svg>'
    },
    {
      name: 'Crown',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M5 16L3 10l5.5 5L12 4l3.5 11L21 10l-2 6H5z"/></svg>'
    },
    {
      name: 'Gem',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M6 2l6 8 6-8h3l-9 20L3 2h3z"/></svg>'
    },
    {
      name: 'Potion',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 2v4H7v2h2v2l-4 8h12l-4-8V8h2V6h-2V2H9z"/></svg>'
    },
    {
      name: 'Star Badge',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>'
    }
  ].freeze
end