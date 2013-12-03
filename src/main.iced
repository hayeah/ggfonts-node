express = require('express')
app = express()
request = require("request")


# http://fonts.googleapis.com/css?family=Signika+Negative:300
GOOGLE_FONTS_DOMAIN = "http://fonts.googleapis.com"

class Cache
  constructor: ->

  # Store a string as cache
  # @param key {String}
  # @param str {String}
  put: (key,str) ->
    throw "abstract"
  #
  get: (key) ->
    throw "abstract"

  # bust cache
  # bust: ->

class MemoryCache
  constructor: ->
    @_cache = {}

  put: (key,str) ->
    @_cache[key] = str

  get: (key) ->
    @_cache[key]

# class RedisCache
#   constructor: (arguments) ->
#     # ...

# class FileCache
#   constructor: (arguments) ->
#     throw "unimplemented"


class GoogleFont
  cache: new MemoryCache()
  constructor: (@url) ->

  getCSS: (cb) ->
    if css = @cache.get(@url)
      cb(null,css)
      return

    await @loadCSS(defer(err,css))

    if err
      cb(err)
      return

    css = @transformCSS(css)

    # cache it
    @cache.put(@url,css)
    cb(null,css)

  loadCSS: (cb) ->
    request.get {
      url: @url
      encoding: "utf8"
      timeout: 5000
      }, (err,response,body) ->
      cb(err,body)

  ### sample css
  @font-face {
    font-family: 'Signika Negative';
    font-style: normal;
    font-weight: 300;
    src: local('Signika Negative Light'), local('SignikaNegative-Light'), url(http://themes.googleusercontent.com/static/fonts/signikanegative/v2/q5TOjIw4CenPw6C-TW06FkYcuY_p1FpnGh_-AVRTy68.ttf) format('truetype');
  }
  ###

  transformCSS: (css) ->
    lines = css.split("\n")
    lines = @rewriteURL(lines)
    lines.join "\n"

  # rewrite the font URL to local
  FONT_ROOT = "http://themes.googleusercontent.com/static/"
  rewriteURL: (lines) ->
    lines = for line in lines
      re = /.*src:.*(url\((.+)\)) /
      if m = re.exec(line)
        console.log ["match",line]
        fontURL = m[2]
        newFontURL = fontURL.replace(FONT_ROOT,"/")
        console.log ["new", newFontURL]
        line2 = line.replace(/url\(.*\)/,"url(#{newFontURL})")
        console.log ["replaced", line2]
        line2
      else
        line

    return lines

app.get '/css', (req,res) ->
  resource_url = "#{GOOGLE_FONTS_DOMAIN}#{req.originalUrl}"
  console.log "get", resource_url
  font = new GoogleFont(resource_url)
  await font.getCSS(defer(err,css))
  console.log ["req end", err, css]
  res.end(css)

port = 4000
console.log "listening on #{port}"
app.listen(port);