# Firebase configuration
class Firebase
  class << self
    def config
      @config ||= {
        apiKey: Rails.application.credentials.dig(:firebase, :api_key),
        authDomain: Rails.application.credentials.dig(:firebase, :auth_domain),
        projectId: Rails.application.credentials.dig(:firebase, :project_id),
        storageBucket: Rails.application.credentials.dig(:firebase, :storage_bucket),
        messagingSenderId: Rails.application.credentials.dig(:firebase, :messaging_sender_id),
        appId: Rails.application.credentials.dig(:firebase, :app_id)
      }
    end

    def project_id
      config[:projectId]
    end

    def configured?
      config.values.all?(&:present?)
    end

    def enabled_auth_providers
      @enabled_auth_providers ||= Rails.application.config.firebase_auth_providers || [ "google", "github" ]
    end

    def provider_enabled?(provider)
      enabled_auth_providers.include?(provider.to_s)
    end
  end
end

# Optional: Set up Google Cloud Firestore if needed
if Firebase.configured?
  require "google/cloud/firestore"

  Google::Cloud::Firestore.configure do |config|
    config.project_id = Firebase.project_id
    # We'll add more configuration as needed
  end
end