# PostHog Analytics Setup

This guide explains how to set up PostHog analytics in your Voluntariness application using the official `posthog-ruby` gem.

## Configuration

### Rails Credentials (Recommended)

The preferred way to configure PostHog is using Rails credentials:

```bash
# Edit credentials
rails credentials:edit
```

Add your PostHog configuration:

```yaml
posthog:
  project_key: ....
  api_host: https://eu.i.posthog.com  # Optional, defaults to EU instance
  ui_host: https://eu.posthog.com     # Optional, defaults to EU instance
```

### Environment Variables (Fallback)

Alternatively, you can use environment variables (credentials take precedence):

```bash
POSTHOG_PROJECT_KEY=....
POSTHOG_API_HOST=https://eu.i.posthog.com  # Optional
POSTHOG_UI_HOST=https://eu.posthog.com     # Optional
```

**Note**: The configuration defaults to the European PostHog instance (`eu.i.posthog.com`). If you're using the US instance, update the `api_host` accordingly.

### Development/Testing

By default, PostHog is disabled in development and test environments. To enable it for testing:

1. Edit `config/posthog.yml`
2. Change `enabled: false` to `enabled: true` for development
3. Ensure your credentials contain the PostHog configuration (the config will automatically read from credentials)

## Features Implemented

### 🎯 Event Tracking (Server-First Approach)

**Primary Server-side Events:**
- User sign-up/sign-in
- Household creation
- Task completion (with bonus points tracking)
- Page views (automatic on all successful page loads)
- Theme changes (via API)

**Minimal Client-side Events:**
- Theme changes (immediate UI feedback)
- Custom user interactions (when immediate feedback is needed)

### 👤 User Identification

Users are automatically identified with:
- Email address
- Subscription plan
- Theme preference 
- Account creation date
- Number of households

### 📊 Custom Properties

Events include rich context:
- Task details (title, points, interval)
- Participant information
- Household context
- Bonus points calculations
- Theme preferences

## Usage

### Server-side Tracking (Primary Method)

Most events are automatically tracked server-side:

- **Page views**: Automatically tracked on all successful page loads
- **User actions**: Tracked when users interact with your app (task completion, household creation, etc.)
- **API calls**: Theme changes and other API interactions are tracked

### Client-side Tracking (Minimal Use)

Only use client-side tracking for immediate UI feedback:

```html
<!-- Only for immediate feedback scenarios -->
<button data-controller="posthog" 
        data-action="click->posthog#track"
        data-posthog-event-value="immediate_action"
        data-posthog-properties-value='{"feedback": "immediate"}'>
  Immediate Feedback Action
</button>
```

### Server-side Tracking

Use the `PosthogService` for server-side events (uses the official `posthog-ruby` gem):

```ruby
# Track an event
PosthogService.track(user_id, 'custom_event', {
  property1: 'value1',
  property2: 'value2'
})

# Identify a user
PosthogService.identify(user_id, {
  email: user.email,
  plan: 'premium'
})

# Create an alias (useful for linking anonymous users to identified users)
PosthogService.alias(user_id, anonymous_id)
```

**Background Jobs**: In production, events are sent via background jobs for better performance. In development, they're sent immediately for easier debugging.

### Why Server-First?

This implementation prioritizes server-side tracking because:

- **🚫 Ad-blocker proof**: Server events can't be blocked by ad blockers
- **📊 More reliable**: No dependency on client-side JavaScript execution
- **🔒 Privacy compliant**: Sensitive user data stays on your server
- **⚡ Better performance**: Reduces client-side JavaScript load
- **📈 Complete data**: Works even when JavaScript is disabled

## Privacy & GDPR

The implementation includes privacy-friendly defaults:
- Input masking for sensitive fields
- localStorage + cookie persistence
- Person profiles only for identified users
- Session recording with input masking

## Testing

In development, events are logged to console when PostHog is disabled. Enable debug mode to see detailed logging.

## Security Notes

- **Rails Credentials**: The configuration prioritizes Rails credentials over environment variables for better security
- **Credentials are encrypted**: Rails credentials are encrypted and version-controlled safely
- **Environment fallback**: Environment variables work as a fallback for deployment flexibility
- **No credentials in logs**: The PostHog client handles credentials securely without logging them

## Troubleshooting

1. **Events not appearing**: Check that your PostHog project key is set in Rails credentials or environment variables
2. **Console errors**: Verify the API host is correct for your PostHog instance (EU vs US)
3. **No user identification**: Ensure users are signed in and `current_user` is available
4. **Credentials issues**: Run `rails credentials:show` to verify your PostHog configuration is present

## Events Reference

### Core Events

| Event | Trigger | Properties |
|-------|---------|------------|
| `user_signed_up` | New user registration | email, provider, theme_preference |
| `user_signed_in` | User login | email, provider, total_households |
| `household_created` | New household | household_name, default_tasks_created |
| `task_completed` | Task completion | task_title, participant_name, bonus_points |
| `theme_changed` | Theme toggle | new_theme, previous_theme |
| `$pageview` | Page navigation | page_title, current_url |

### Custom Events

You can easily add more events using the Stimulus controller or PosthogService as needed.