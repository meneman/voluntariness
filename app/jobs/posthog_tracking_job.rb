class PosthogTrackingJob < ApplicationJob
  queue_as :default
  
  def perform(action, payload)
    return unless PosthogConfig.enabled?
    
    client = PosthogConfig.client
    return unless client
    
    case action
    when 'track'
      client.capture(payload)
    when 'identify'
      client.identify(payload)
    when 'alias'
      client.alias(payload)
    else
      Rails.logger.error "Unknown PostHog action: #{action}"
    end
    
  rescue => e
    Rails.logger.error "PostHog tracking job error: #{e.message}"
    raise e if Rails.env.development?
  end
end