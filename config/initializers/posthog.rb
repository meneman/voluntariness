require 'posthog'

# PostHog Analytics Configuration
module PosthogConfig
  CONFIG = Rails.application.config_for(:posthog)
  
  def self.enabled?
    CONFIG['enabled'] && CONFIG['project_key'].present?
  end
  
  def self.project_key
    CONFIG['project_key']
  end
  
  def self.api_host
    CONFIG['api_host']
  end
  
  def self.ui_host
    CONFIG['ui_host']
  end
  
  def self.debug?
    CONFIG['debug']
  end
  
  def self.client
    return @client if @client
    return nil unless enabled?
    
    @client = PostHog::Client.new({
      api_key: project_key,
      host: api_host,
      on_error: Proc.new { |status, msg| 
        Rails.logger.error "PostHog error (#{status}): #{msg}"
      }
    })
  end
  
  def self.config_for_js
    return nil unless enabled?
    
    {
      project_key: project_key,
      api_host: api_host,
      ui_host: ui_host,
      debug: debug?,
      capture_pageview: false,
      capture_pageleave: true,
      persistence: 'localStorage+cookie',
      session_recording: {
        maskAllInputs: true,
        maskInputOptions: {
          password: true,
          email: false
        }
      },
      person_profiles: 'identified_only',
      loaded: ->(posthog) {
        if Rails.env.development?
          puts "PostHog loaded successfully"
        end
      }
    }
  end
end