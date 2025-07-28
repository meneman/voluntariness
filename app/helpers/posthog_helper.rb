module PosthogHelper
  def posthog_enabled?
    PosthogConfig.enabled?
  end
  
  def posthog_config_json
    config = PosthogConfig.config_for_js
    return '{}' unless config
    
    config.to_json.html_safe
  end
  
  def posthog_user_properties
    return '{}' unless current_user && posthog_enabled?
    
    {
      email: current_user.email,
      plan: current_user.plan_display_name,
      theme_preference: current_user.theme_preference,
      streak_bonuses_enabled: current_user.streak_boni_enabled,
      overdue_bonus_enabled: current_user.overdue_bonus_enabled,
      households_count: current_user.households.count,
      current_household: current_user.current_household&.name,
      created_at: current_user.created_at.iso8601
    }.to_json.html_safe
  end
  
  def posthog_identify_script
    return '' unless current_user && posthog_enabled?
    
    javascript_tag do
      raw <<~JS
        if (typeof posthog !== 'undefined') {
          posthog.identify('#{current_user.id}', #{posthog_user_properties});
        }
      JS
    end
  end
end