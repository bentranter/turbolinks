# Turbolinks

[![Build Status](https://travis-ci.org/bentranter/turbolinks.svg?branch=master)](https://travis-ci.org/bentranter/turbolinks) [![License](https://img.shields.io/github/license/bentranter/turbolinks.svg)](https://github.com/bentranter/turbolinks/blob/master/LICENSE)

Crystal engine for Turbolinks integration. Extends `HTTP::Handler`, so you can use it as middleware in any web application. Don't forget to grab the [frontend code for Turbolinks](https://github.com/turbolinks/turbolinks).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  turbolinks:
    github: bentranter/turbolinks
```

## Warning

The `Location` header that is provided on a redirect after a form submit is used to set the value of  `location` in `Turbolinks.visit(location)`. This value is current **not escaped** and opens you up to JS injection -- please escape this value manually, or wait until a fix is pushed to this repo.

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
