require "./spec_helper"
require "uri"

# Redirection helper, like Rails' `redirect_to`.
def redirect_to(context, url)
  context.response.status_code = 302

  url = URI.escape(url) { |b| URI.unreserved?(b) || b != '/' }
  context.response.headers.add "Location", url
end

describe Turbolinks::Handler do
  it "should respond normally" do
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/")
    request.headers["Turbolinks-Referrer"] = "/"
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    handler = Turbolinks::Handler.new
    handler.next = Turbolinks::Handler::Proc.new do |ctx|
      ctx.response.print "Hello"
    end
    handler.call(context)
    response.close

    io.rewind
    io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHello")
  end

  it "should set a cookie for redirects occuring during a GET request" do
    io = IO::Memory.new
    request = HTTP::Request.new("Get", "/")
    request.headers["Turbolinks-Referrer"] = "/"
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    handler = Turbolinks::Handler.new
    handler.next = Turbolinks::Handler::Proc.new do |ctx|
      redirect_to ctx, "/"
    end
    handler.call(context)
    response.close

    context.request.cookies.each do |cookie|
      puts cookie
    end

    location = context.response.cookies["_turbolinks_location"].value
    location.should eq "/"
  end

  it "should redirect after a POST form submission" do
    io = IO::Memory.new
    request = HTTP::Request.new("POST", "/")
    request.headers["Turbolinks-Referrer"] = "/"
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    handler = Turbolinks::Handler.new
    handler.next = Turbolinks::Handler::Proc.new do |ctx|
      redirect_to ctx, "/"
    end
    handler.call(context)
    response.close

    io.rewind
    io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Type: text/javascript\r\nContent-Length: 67\r\n\r\nTurbolinks.clearCache();Turbolinks.visit('/', {action: 'advance'});")
  end
end
