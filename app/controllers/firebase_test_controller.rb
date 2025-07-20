class FirebaseTestController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :test_config, :test_page ]

  def test_config
    config_status = {
      firebase_configured: firebase_configured?,
      firebase_config: firebase_configured? ? "✅ Configured" : "❌ Missing credentials",
      project_id: Rails.application.credentials.dig(:firebase, :project_id) || "Not set",
      debug_credentials: Rails.application.credentials.firebase
    }

    render json: config_status
  end

  private

  def firebase_configured?
    Rails.application.credentials.dig(:firebase, :api_key).present? &&
    Rails.application.credentials.dig(:firebase, :project_id).present?
  end

  def test_page
    # Simple test page to verify Firebase initialization from localhost
    render html: <<~HTML.html_safe
      <!DOCTYPE html>
      <html>
      <head>
        <title>Firebase Localhost Test</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          .status { padding: 20px; border-radius: 8px; margin: 20px 0; }
          .success { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
          .error { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
          pre { background: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto; }
        </style>
      </head>
      <body>
        <h1>🔥 Firebase Localhost Test</h1>
        <p><strong>Host:</strong> #{request.host}:#{request.port}</p>
        <p><strong>Environment:</strong> #{Rails.env}</p>
        
        <div id="status" class="status">🔄 Loading Firebase...</div>
        <div id="details"></div>
        
        <script type="module">
          const firebaseConfig = #{Firebase.config.to_json};
          
          console.log('Testing Firebase from localhost...');
          console.log('Config:', firebaseConfig);
          
          try {
            // Import Firebase modules using our importmap configuration
            const { initializeApp } = await import('firebase/app');
            const { getAuth, connectAuthEmulator } = await import('firebase/auth');
            
            console.log('Firebase modules imported successfully');
            
            // Initialize Firebase
            const app = initializeApp(firebaseConfig);
            console.log('Firebase app initialized');
            
            // Initialize Auth
            const auth = getAuth(app);
            console.log('Firebase Auth initialized');
            
            // Success!
            document.getElementById('status').innerHTML = '✅ Firebase successfully initialized from localhost!';
            document.getElementById('status').className = 'status success';
            document.getElementById('details').innerHTML = `
              <h3>✅ Success Details:</h3>
              <pre>Project ID: ${firebaseConfig.project_id}
Auth Domain: ${firebaseConfig.auth_domain}
App ID: ${firebaseConfig.app_id}
Environment: Localhost development
Status: Ready for authentication</pre>
              <p><strong>Next step:</strong> Try the <a href="/sign_in">sign-in page</a></p>
            `;
            
          } catch (error) {
            console.error('Firebase initialization failed:', error);
            document.getElementById('status').innerHTML = '❌ Firebase initialization failed from localhost';
            document.getElementById('status').className = 'status error';
            document.getElementById('details').innerHTML = `
              <h3>❌ Error Details:</h3>
              <pre>${error.name}: ${error.message}

Stack trace:
${error.stack}</pre>
              <h4>Possible solutions:</h4>
              <ul>
                <li>Check that localhost is added to authorized domains in Firebase Console</li>
                <li>Verify Firebase project configuration</li>
                <li>Check browser console for additional errors</li>
                <li>Try using Firebase Local Emulator for development</li>
              </ul>
            `;
          }
        </script>
      </body>
      </html>
    HTML
  end

  def test_token
    token = params[:token]

    if token.blank?
      render json: { error: "No token provided" }, status: :bad_request
      return
    end

    begin
      firebase_service = FirebaseAuthService.new
      decoded_token = firebase_service.verify_id_token(token)

      render json: {
        success: true,
        decoded_token: decoded_token,
        message: "Token verification successful"
      }
    rescue FirebaseAuthService::InvalidTokenError => e
      render json: {
        success: false,
        error: e.message
      }, status: :unauthorized
    end
  end
end
