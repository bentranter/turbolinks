require "http"
require "html"
require "./turbolinks/*"

# Turbolinks a module that provides HTTP middleware to be used with
# Turbolinks powered frontends. It handles form submission, and redirection.
module Turbolinks
  # A handler that handles form submission and redirection for Turbolinks
  # enabled frontends. It does nothing if the frontend is not using
  # Turbolinks, so it can safely be used as HTTP middleware for any
  # application.
  #
  # Use like you would use any HTTP middleware:
  #
  #     require "http/server"
  #     require "turbolinks"
  #
  #     HTTP::Server.new("127.0.0.1", 3000, [
  #       Turbolinks::Handler.new,
  #     ]).listen
  #
  class Turbolinks::Handler
    include HTTP::Handler

    @@turbolinks_location = "_turbolinks_location"

    # Executes the middleware. This function is called by the HTTP server
    # after you've registered it as middleware, so you won't need to use this
    # function directly.
    def call(context : HTTP::Server::Context)
      return call_next context unless context.request.headers.get?("Turbolinks-Referrer")

      if context.request.method == "POST"
        call_next context
        post(context)
        return
      end

      check_redirect(context)
      call_next context
      get(context)
    end

    # Handles the Turbolinks POST requets behaviour, specifically, it handles
    # the conditions that occur during a redirect after a POST request.
    private def post(context : HTTP::Server::Context)
      # Remove the location header, since we're no longer redirecting.
      return unless context.response.headers.get?("Location")

      # Get the location before resetting the response.
      location = context.response.headers.delete("Location")

      # Save headers.
      headers = context.response.headers.dup

      # Reset the response so we can add out new headers and body.
      context.response.reset

      # Put the old headers back on the response.
      context.response.headers.merge!(headers)

      # TODO(ben) escape JS output!
      context.response.headers["Content-Type"] = "text/javascript"
      context.response.status_code = 200
      context.response.print "Turbolinks.clearCache();Turbolinks.visit('#{location}', {action: 'advance'});"
    end

    # If the Turbolinks cookie is found, then redirect to the location specified
    # in the cookie via the `Turbolinks-Location` header that the Turbolinks
    # frontend will handle.
    private def check_redirect(context : HTTP::Server::Context)
      return unless context.request.cookies[@@turbolinks_location]?

      cookie = context.request.cookies[@@turbolinks_location]
      context.response.headers["Turbolinks-Location"] = cookie.value

      # Update the cookie so it gets expired by the browser.
      cookie.expires = Time.epoch(0)
      context.response.cookies[@@turbolinks_location] = cookie
    end

    # Handles the Turbolinks behaviour that may occur during a GET request.
    private def get(context)
      return unless context.response.headers.get?("Location")

      location = context.response.headers.get("Location").to_s
      cookie = HTTP::Cookie.new(@@turbolinks_location, "/", http_only: true)
      context.response.cookies[@@turbolinks_location] = cookie
    end
  end
end
