# encoding: utf-8

# Notes: While this is perfectly functional, I think I would prefer a plugin-style approach, 
# such that one can get the base application but enable and disable endpoints based on 
# available plugins. That means the oEmbed provider and the symbol resolver would each be 
# separate plugins, allowing users to omit the ones they don't want to use.
# Worth investigating, but not my priority yet...

class Services
  def self.call(env)
    req = Rack::Request.new(env)
    
    #Parse the incoming path to see which portion of the app to use
    case req.path
    when /^\/services$/,/^\/services\/$/
      # /services or /services/ - Display services landing page
      # To do: build this...
      Rack::Response.new("This is the landing page where we describe the available services.")
    when /^\/services\/symbol\/(.*)/
      # /services/symbol/* - Try to resolve the symbol to a URL and redirect to it
      symbol = URI::encode(req.path.split(/\/symbol\//).last)
      url = resolve_symbol(symbol)
      if url
        #Rack::Response.new(url)
        res = Rack::Response.new
        res.redirect(url)
        res.finish
      else
        Rack::Response.new($error_404 + $go_home,404,{'Content-Type' => 'text/html'})
      end
    when /^\/services\/resolve\/(.*)/
      # /services/resolve/* - Try to resolve the symbol to a URL and display it as a JSON result
      symbol = URI::encode(req.path.split(/\/resolve\//).last)
      url = resolve_symbol(symbol)
      if url && url =~ /handle\/11176\/(\d+)/
        res = Rack::Response.new("{\"url\": \"#{url}\"}",200,{'Content-Type' => 'application/json'})
      else
        Rack::Response.new($error_404 + $go_home,404,{'Content-Type' => 'text/html'})
      end
    when /^\/services\/oembed$/,/^\/services\/oembed\/$/
      # /services/oembed and /services/oembed/ - Populate an oEmbed response for embedding in external sites.
      if req.params["url"]
        if req.params["url"] =~ /(.*)\.un\.org\/handle\/(.*)/
          url = req.params["url"]
          # Generate a response based on the url supplied
          # But first, let's whitelist some parameters because paranoia pays off
          params = whitelist_params(["url","maxwidth","maxheight","container"],req.params)
          response = generate_oembed(url,params)
          Rack::Response.new(response,200,{'Content-Type' => 'application/json'})
        else
          additional_info = "<p>The URL you supplied is not within the defined URL schemes accepted by this application.</p>"
          Rack::Response.new($error_403 + additional_info + $go_home,403,{'Content-Type' => 'text/html'})
        end
      else
        additional_info = "<p>'url' is a required parameter</p>"
        Rack::Response.new($error_400 + additional_info + $go_home,400,{'Content-Type' => 'text/html'})
      end
    when /^\/services\/embed\/handle\/11176\/(\d+)$/
      # /services/embed/handle/11176/* - Make a de-styled version of the content either for inclusion in an iframe or for DOM insertion via javascript
      url = $repository_url + "/" + req.path.split(/\/embed\//).last
      # whitelist parameters
      params = whitelist_params(["metadata"],req.params)
      response = unstyle(url,params)
      if response
        Rack::Response.new(response,200,{'Content-Type' => 'text/html'})
      else
        Rack::Response.new($error_404 + "<p>#{url},#{params}</p>",404,{'Content-Type' => 'text/html'})
      end
    else
      Rack::Response.new($error_404 + $go_home,404,{'Content-Type' => 'text/html'})
    end
  end
end