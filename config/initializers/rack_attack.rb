# Rack::Attack configuration for rate limiting
class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache for storing throttle data
  Rack::Attack.cache.store = Rails.cache

  ### Throttle Strategies ###

  # Throttle all requests by IP (100 requests per minute)
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end

  # Throttle login attempts by IP (5 requests per 20 seconds)
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email (5 requests per minute)
  throttle('logins/email', limit: 5, period: 1.minute) do |req|
    if req.path == '/login' && req.post?
      # Extract email from request body
      begin
        body = JSON.parse(req.body.read)
        req.body.rewind
        body.dig('user', 'email')&.downcase
      rescue JSON::ParserError
        nil
      end
    end
  end

  # Throttle signup attempts by IP (3 requests per minute)
  throttle('signups/ip', limit: 3, period: 1.minute) do |req|
    if req.path == '/signup' && req.post?
      req.ip
    end
  end

  # Throttle API requests by authenticated user (300 requests per minute)
  throttle('api/user', limit: 300, period: 1.minute) do |req|
    if req.path.start_with?('/api/')
      # Extract user ID from JWT token if present
      auth_header = req.env['HTTP_AUTHORIZATION']
      if auth_header&.start_with?('Bearer ')
        token = auth_header.split(' ').last
        begin
          payload = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key, true, algorithm: 'HS256')
          payload.first['sub'] # User ID
        rescue JWT::DecodeError
          req.ip # Fall back to IP if token is invalid
        end
      else
        req.ip
      end
    end
  end

  ### Custom Responses ###

  # Return JSON response for throttled requests
  self.throttled_responder = lambda do |req|
    match_data = req.env['rack.attack.match_data']
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{
        error: 'Rate limit exceeded',
        message: "Too many requests. Retry after #{retry_after} seconds.",
        retry_after: retry_after
      }.to_json]
    ]
  end

  ### Blocklist ###

  # Block requests from banned IPs (can be managed via Rails cache)
  blocklist('block bad IPs') do |req|
    Rails.cache.read("blocked:#{req.ip}")
  end

  ### Safelist ###

  # Allow all requests from localhost in development
  safelist('allow from localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1' if Rails.env.development?
  end
end
