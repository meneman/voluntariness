class Rack::Attack
  # Configure Cache
  # Use Solid Cache for single-server deployment (both development and production)
  # Solid Cache provides excellent performance and persistence for single-server setups
  Rack::Attack.cache.store = Rails.cache

  # Safelist requests from localhost and trusted IPs
  # Allows requests from localhost in development and local testing
  safelist("allow from localhost") do |req|
    "127.0.0.1" == req.ip || "::1" == req.ip
  end

  # Safelist asset requests to reduce noise
  safelist("asset requests") do |req|
    req.path.start_with?("/assets/")
  end

  # Safelist your server IP and any trusted monitoring/health check IPs
  safelist("allow from trusted IPs") do |req|
    # Add your server IP or monitoring service IPs here
    # ["192.168.178.55", "10.0.0.0/8"].any? { |trusted_ip| IPAddr.new(trusted_ip).include?(req.ip) }
    false # Disabled by default - uncomment and add your trusted IPs
  end

  # Throttle requests to login attempts by IP address
  # Allows 5 login attempts per minute from same IP
  throttle("logins/ip", limit: 5, period: 1.minute) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email param
  # Allows 5 login attempts per minute for same email
  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Return the email, or nil to not throttle
      req.params["user"].try(:[], "email").presence
    end
  end

  # Generic request throttling by IP
  # More restrictive in production, generous in development
  throttle("requests by ip", limit: Rails.env.production? ? 100 : 300, period: 1.minute) do |req|
    req.ip
  end

  # Throttle API requests more strictly if you have API endpoints
  # Allows 60 requests per minute for API endpoints
  throttle("api requests by ip", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  # Block suspicious requests
  # Block requests with suspicious SQL injection patterns
  blocklist("bad actors") do |req|
    # Block requests with obvious SQL injection attempts
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      req.query_string =~ /(\bunion\b.*\bselect\b)|(\bselect\b.*\bunion\b)/i ||
      req.query_string =~ /(\bdrop\b.*\btable\b)|(\btable\b.*\bdrop\b)/i ||
      req.params.to_s =~ /(\bunion\b.*\bselect\b)|(\bselect\b.*\bunion\b)/i
    end
  end

  # Production-specific: Block requests from known bad User-Agents
  blocklist("block bad user agents") do |req|
    if Rails.env.production?
      # Block common scraping and attack tools
      user_agent = req.user_agent.to_s.downcase
      %w[
        sqlmap masscan nmap nikto dirb gobuster
        python-requests curl wget
      ].any? { |bad_agent| user_agent.include?(bad_agent) }
    else
      false
    end
  end

  # Note: Allow2Ban for repeat offenders can be added later if needed
  # It requires more careful setup to avoid initialization errors

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    retry_after = (req.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ { error: "Too many requests. Please try again later." }.to_json ]
    ]
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |req|
    [
      403,
      { "Content-Type" => "application/json" },
      [ { error: "Forbidden" }.to_json ]
    ]
  end

  # Log blocked and throttled requests in development (excluding routine safelisted requests)
  if Rails.env.development?
    ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
      req = payload[:request]
      match_type = req.env["rack.attack.matched"]
      
      # Only log throttles and blocks, not routine safelisted requests
      if match_type && !match_type.include?("allow")
        puts "[Rack::Attack] #{req.env["rack.attack.match_discriminator"]} #{match_type}"
      end
    end
  end
end
