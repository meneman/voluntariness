class PosthogService
  def self.track(user_id, event_name, properties = {})
    return unless PosthogConfig.enabled?
    
    client = PosthogConfig.client
    return unless client
    
    # Use background job in production for better performance
    if Rails.env.production?
      PosthogTrackingJob.perform_later('track', {
        distinct_id: user_id.to_s,
        event: event_name,
        properties: properties.merge(
          timestamp: Time.current.iso8601,
          source: 'server'
        )
      })
    else
      # Immediate tracking in development
      client.capture({
        distinct_id: user_id.to_s,
        event: event_name,
        properties: properties.merge(
          timestamp: Time.current.iso8601,
          source: 'server'
        )
      })
    end
  rescue => e
    Rails.logger.error "PostHog tracking error: #{e.message}"
  end
  
  def self.identify(user_id, properties = {})
    return unless PosthogConfig.enabled?
    
    client = PosthogConfig.client
    return unless client
    
    # Use background job in production
    if Rails.env.production?
      PosthogTrackingJob.perform_later('identify', {
        distinct_id: user_id.to_s,
        properties: properties.merge(
          last_seen: Time.current.iso8601
        )
      })
    else
      # Immediate identification in development  
      client.identify({
        distinct_id: user_id.to_s,
        properties: properties.merge(
          last_seen: Time.current.iso8601
        )
      })
    end
  rescue => e
    Rails.logger.error "PostHog identification error: #{e.message}"
  end
  
  def self.alias(user_id, alias_id)
    return unless PosthogConfig.enabled?
    
    client = PosthogConfig.client
    return unless client
    
    if Rails.env.production?
      PosthogTrackingJob.perform_later('alias', {
        distinct_id: user_id.to_s,
        alias: alias_id.to_s
      })
    else
      client.alias({
        distinct_id: user_id.to_s,
        alias: alias_id.to_s
      })
    end
  rescue => e
    Rails.logger.error "PostHog alias error: #{e.message}"
  end
end