module SeoHelper
  def seo_title(title = nil)
    base_title = "Voluntariness - Household Task Management"
    title ? "#{title} | #{base_title}" : base_title
  end

  def seo_description(description = nil)
    description || "Manage household tasks with gamification. Track completion, earn points, and motivate room mates with streaks and bonuses."
  end

  def seo_keywords
    "household tasks, task management, chores organization, gamification, chores, household management, task tracking"
  end

  def seo_image(image = nil)
    image || asset_url("seifenblasen4.png")
  end

  def canonical_url(url = nil)
    url || request.original_url
  end
end
