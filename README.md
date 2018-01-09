# Turbolinks

[![Build Status](https://travis-ci.org/bentranter/turbolinks.svg?branch=master)](https://travis-ci.org/bentranter/turbolinks) [![License](https://img.shields.io/github/license/bentranter/turbolinks.svg)](https://github.com/bentranter/turbolinks/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/bentranter/turbolinks.svg)](https://github.com/bentranter/turbolinks/releases)

Crystal engine for Turbolinks integration. Extends `HTTP::Handler`, so you can use it as middleware in any web application. Don't forget to grab the [frontend code for Turbolinks](https://github.com/turbolinks/turbolinks).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  turbolinks:
    github: bentranter/turbolinks
```

## Usage

Turbolinks extends `HTTP::Handler`, so it can be used as HTTP middleware. You can use it with the standard library like so:

```crystal
require "http/server"
require "turbolinks"

HTTP::Server.new("127.0.0.1", 3000, [
  Turbolinks::Handler.new,
]).listen
```

or with a framework that supports standard HTTP middleware. For example, you can use Turbolinks with Kemal like so:

```crystal
require "kemal"
require "turbolinks"

# Calling `add_handler` is Kemal's way of registering HTTP middleware.
add_handler Turbolinks::Handler.new

get "/"
  "Served by Turbolinks!"
end

Kemal.run
```

## A Note About Security

A common pattern if you're coming from the Rails world (and using something like [rails-ujs](https://github.com/rails/rails/tree/master/actionview/app/assets/javascripts)) a common approach is to handle a `POST` request, and then redirect to another route. Turbolinks handles this case by intercepting the redirection after the `POST` request executes, and then responding with a JavaScript snippet to execute `Turbolinks.visit("#{location}")` for the location to redirect to.

While this is typically safe, if your handler allows the user to input this `location`, you open yourself up to JavaScript injection. Lets look at two examples where a user is leaving a comment, submitted through a form `post` request.

```crystal
require "kemal"
require "turbolinks"

add_handler Turbolinks::Handler.new

# Unsafe approach!
post "/unsafe-comment" do |env|
  title = env.params.body["title"]
  comment = env.params.body["comment"]

  # Imagine `new_comment` does something to handle a new commment, for
  # example's sake.
  new_comment(title, comment)

  # This is dangerous because the value of `title` here could be anything --
  # including malicious JavaScript. Since the frontend will excute JavaScript
  # containing the value of this redirect here, any malicious JavaScript will
  # execute.
  env.redirect "/comments/#{title}"
end

# Safe approach.
post "/safe-comment" do |env|
  title = env.params.body["title"]
  comment = env.params.body["comment"]

  # Imagine `new_comment` does something to handle a new commment, for
  # example's sake.
  comment_id = new_comment(title, comment)

  # This is safe because there's no way for the user submitted `title` or
  # `comment` to be available in the returned JavaScript -- you generate an
  # ID, and redirect to that route.
  env.redirect "/comments/#{comment_id}"
end

Kemal.run
```

If you _must_ do something like the unsafe approach, you'll need to sanitize the input yourself.

## A Note For Non `rails-ujs` Users

In order for form submissions _not_ to trigger a full page reload, you'll need to ensure that those submissions are submitted as AJAX requests. While a library like [Rails-UJS](https://github.com/rails/rails/tree/master/actionview/app/assets/javascripts) or [JQuery-UJS](https://github.com/rails/jquery-ujs) would handle this for you, it's straightforward to implement this yourself. The following JavaScript snippet adds bare-minimum support for AJAX form submissions that work with Turbolinks, but I encourage to look at what `rails-ujs` does as well.

```js
(function() {
  "use strict";
  /*
   * For Google Analytics, you need this:
   * <body>
   * <script>_gaq.push(['_trackPageview']);</script>
   *  ...the rest of the body here...
   * </body>
   * See https://coderwall.com/p/ypzfdw/faster-page-loads-with-turbolinks for
   * more info.
   */

   /*
    * By default, Turbolinks submits forms normally. While this may feel
    * frustrating as a consumer of the library, it makes sense:
    *   - No specialized logic on the backend
    *   - Cache is purged since the page refreshed.
    * However, that's not always what you want. By using the functionality
    * below, forms are submitted via AJAX, as recommended in the Turbolinks
    * documentation.
    */
    document.addEventListener("DOMContentLoaded", function() {
      /**
       * submit sends an HTTP request via XHR.
       * @param {*Object} formEl - the form element to submit via XHR.
       */
      function submit(formEl) {
        var xhr = new XMLHttpRequest();
        xhr.open(formEl.method, formEl.action, true);

        /* See
         * https://github.com/rails/rails/blob/master/actionview/app/assets/javascripts/rails-ujs/utils/ajax.coffee
         * for a more in-depth usage.
         */
        xhr.onreadystatechange = function() {
          if (xhr.readyState === 4 && xhr.status === 200) {
            var script = document.createElement("script");
            script.innerText = xhr.responseText;
            document.head.appendChild(script).parentNode.removeChild(script);
          }
        }
        /* Set relevant headers that some backends check for */
        xhr.setRequestHeader("Turbolinks-Referrer", window.location.href);
        xhr.setRequestHeader("X-Requested-With", "xhr");
        xhr.send(new FormData(formEl));
        return false;
      }

      /* Intercept **any** submit event to submit via XHR instead. */
      document.addEventListener("submit", function(e) {
        e.preventDefault();
        if (e.srcElement) {
          submit(e.srcElement);
        }
      });
    });
})();
```

## Development

Turbolinks follows the typical Crystal project structure, so cloning the repo and making changes is all you need to do. However, you're encouraged to run this backend alongside the Turbolinks frontend to make sure it works as expected, especially when compared to the Rails backend. The Turbolinks frontend is available at [github.com/turbolinks/turbolinks](https://github.com/turbolinks/turbolinks), and the Rails gem is available at [github.com/turbolinks/turbolinks-rails](https://github.com/turbolinks/turbolinks-rails).

## Contributing

1. Fork it ( https://github.com/[your-github-name]/turbolinks/fork )
1. Create your feature branch (git checkout -b my-new-feature)
1. Make sure the tests pass, adding any necessary new tests
1. Format your code with `crystal tool format`
1. Commit your changes (git commit -am 'Add some feature')
1. Push to the branch (git push origin my-new-feature)
1. Create a new Pull Request

## Contributors

- [bentranter](https://github.com/bentranter) Ben Tranter - creator, maintainer

## License

The MIT License (MIT). Copyright (c) 2017 Ben Tranter. See the [LICENSE](/LICENSE) for more info.
