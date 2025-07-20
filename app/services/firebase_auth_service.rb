require 'jwt'
require 'net/http'
require 'json'

class FirebaseAuthService
  class InvalidTokenError < StandardError; end
  class UserNotFoundError < StandardError; end

  def initialize
    @project_id = Firebase.project_id
    @public_keys_cache = {}
    @cache_expiry = nil
  end

  # Verify Firebase ID token
  def verify_id_token(id_token)
    raise InvalidTokenError, "Token is blank" if id_token.blank?

    # Decode token header to get the key ID
    header = JWT.decode(id_token, nil, false)[1]
    kid = header['kid']
    
    raise InvalidTokenError, "No key ID found in token" unless kid

    # Get the public key for verification
    public_key = get_public_key(kid)
    
    # Verify and decode the token
    decoded_token = JWT.decode(
      id_token,
      public_key,
      true,
      {
        algorithm: 'RS256',
        iss: "https://securetoken.google.com/#{@project_id}",
        aud: @project_id,
        verify_iat: true,
        verify_exp: true
      }
    )[0]

    # Additional validation
    validate_token_claims(decoded_token)
    
    decoded_token
  rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidIssuerError, JWT::InvalidAudError => e
    Rails.logger.error "JWT verification failed: #{e.message}"
    raise InvalidTokenError, "Token verification failed: #{e.message}"
  end

  # Get user information from Firebase
  def get_firebase_user(uid)
    # For now, we'll just return the UID
    # In a full implementation, you might call Firebase Admin SDK
    { uid: uid }
  rescue => e
    Rails.logger.error "Failed to get Firebase user: #{e.message}"
    raise UserNotFoundError, "User not found: #{e.message}"
  end

  # Find or create local user from Firebase token
  def find_or_create_user_from_token(decoded_token)
    # Firebase UID can be in 'uid' or 'sub' field
    firebase_uid = decoded_token['uid'] || decoded_token['sub']
    email = decoded_token['email']
    
    Rails.logger.info "🔍 Raw token fields: #{decoded_token.keys}"
    Rails.logger.info "🔍 Token 'uid': #{decoded_token['uid']}"
    Rails.logger.info "🔍 Token 'sub': #{decoded_token['sub']}"
    
    Rails.logger.info "🔍 FirebaseAuthService: Looking for user with Firebase UID: #{firebase_uid}"
    Rails.logger.info "🔍 FirebaseAuthService: Email from token: #{email}"
    
    # Validate Firebase UID is present
    if firebase_uid.blank?
      Rails.logger.error "🚨 CRITICAL: Firebase UID is blank! Token: #{decoded_token}"
      raise InvalidTokenError, "Firebase UID is missing from token"
    end
    
    # Try to find existing user by Firebase UID
    user = User.find_by(firebase_uid: firebase_uid)
    Rails.logger.info "📋 Step 1 - User by Firebase UID: #{user ? "#{user.email} (ID: #{user.id})" : 'None'}"
    
    # If not found by Firebase UID, try to find by email (for migration)
    if user.nil? && email.present?
      user = User.find_by(email: email)
      Rails.logger.info "📋 Step 2 - User by Email: #{user ? "#{user.email} (ID: #{user.id})" : 'None'}"
      if user
        # Link existing user to Firebase
        Rails.logger.info "🔗 Linking existing user #{user.email} to Firebase UID #{firebase_uid}"
        user.update!(firebase_uid: firebase_uid)
        Rails.logger.info "✅ User linked successfully"
      end
    end
    
    # Create new user if still not found
    if user.nil?
      Rails.logger.info "🆕 Creating new user: #{email}"
      user = User.create!(
        firebase_uid: firebase_uid,
        email: email,
        role: 'user',
        subscription_plan: 'free',
        subscription_status: 'active'
      )
      Rails.logger.info "✅ New user created: #{user.email} (ID: #{user.id})"
    end
    
    Rails.logger.info "🎯 Final result: #{user.email} (ID: #{user.id}, Firebase UID: #{user.firebase_uid})"
    user
  end

  private

  def get_public_key(kid)
    # Check cache first
    if @cache_expiry && Time.current < @cache_expiry && @public_keys_cache[kid]
      return @public_keys_cache[kid]
    end

    # Fetch public keys from Google
    uri = URI('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
    response = Net::HTTP.get_response(uri)
    
    raise InvalidTokenError, "Failed to fetch public keys" unless response.code == '200'

    # Parse the response
    keys_data = JSON.parse(response.body)
    
    # Cache the keys
    @public_keys_cache = {}
    keys_data.each do |key_id, cert_string|
      cert = OpenSSL::X509::Certificate.new(cert_string)
      @public_keys_cache[key_id] = cert.public_key
    end
    
    # Set cache expiry based on response headers
    cache_control = response['cache-control']
    if cache_control && cache_control.include?('max-age=')
      max_age = cache_control.match(/max-age=(\d+)/)[1].to_i
      @cache_expiry = Time.current + max_age.seconds
    else
      @cache_expiry = Time.current + 1.hour
    end
    
    # Return the requested key
    public_key = @public_keys_cache[kid]
    raise InvalidTokenError, "Public key not found for kid: #{kid}" unless public_key
    
    public_key
  end

  def validate_token_claims(decoded_token)
    # Validate auth_time is not too old (within 5 minutes)
    auth_time = decoded_token['auth_time']
    if auth_time && Time.at(auth_time) < 5.minutes.ago
      raise InvalidTokenError, "Token auth_time is too old"
    end

    # Validate email is verified (optional, depending on your requirements)
    email_verified = decoded_token['email_verified']
    unless email_verified
      Rails.logger.warn "User email is not verified: #{decoded_token['email']}"
      # You can choose to raise an error here if email verification is required
      # raise InvalidTokenError, "Email not verified"
    end
  end
end