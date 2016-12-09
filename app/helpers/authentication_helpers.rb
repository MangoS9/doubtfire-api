#
# The AuthenticationHelpers include functions to check if the user
# is authenticated and to fetch the current user.
#
# This is used by the grape api.
#
module AuthenticationHelpers
  def warden
    env['warden']
  end

  #
  # Checks if the requested user is authenticated.
  # Reads details from the params fetched from the caller context.
  #
  def authenticated?
    user_by_token = User.find_by_auth_token(params[:auth_token]) if params[:auth_token]
    # Check warden -- authenticate using DB or LDAP etc.
    return true if warden.authenticated?
    # Check user by token
    if params[:auth_token] && user_by_token && user_by_token.auth_token_expiry
      # Non-expired token
      return true if user_by_token.auth_token_expiry > DateTime.current
      # Time out this token
      error!({ error: 'Authentication token expired.' }, 419)
    else
      # Add random delay then fail
      sleep((200 + rand(200)) / 1000.0)
      error!({ error: 'Could not authenticate with token. Token invalid.' }, 419)
    end
  end

  # Get the current user either from warden or from the token
  def current_user
    warden.user || User.find_by_auth_token(params[:auth_token])
  end

  #
  # Add the required auth_token to each of the routes for the provided
  # Grape::API.
  #
  def self.add_auth_to(service)
    service.routes.each do |route|
      options = route.instance_variable_get('@options')
      next if options[:params]['auth_token']
      options[:params]['auth_token'] = {
        required: true,
        type:     'String',
        desc:     'Authentication token'
      }
    end
  end

  # Export functions as module functions
  module_function :authenticated?
  module_function :current_user
end
