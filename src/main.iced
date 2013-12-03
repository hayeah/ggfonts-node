express = require('express')
app = express()
request = require("request")
es = require("event-stream")


# http://fonts.googleapis.com/css?family=Signika+Negative:300
GOOGLE_FONTS_DOMAIN = "http://fonts.googleapis.com"
FONT_STATIC_ROOT = "http://themes.googleusercontent.com/static"

class Cache
  constructor: () ->

  # Caches a URL resource.
  # @param key {String}
  # @param stream {Readable}
  cache: (@url) ->
    throw "abstract"

  # Returns
  # @return {Stream}
  data: (key) ->
    throw "abstract"

  head: ->

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

  get: (cb) ->
    console.log ["get",@url]

    if font = @cache.get(@url)
      cb(null,font)
      return

    await @download(defer(err,res,font))
    if err
      cb(err)
      return

    @cache.put(@url,font)
    cb(null,font)

  download: (cb) ->
    request.get {
      url: @url
      timeout: 5000
      encoding: null
    }, cb


class GoogleFontCSS
  cache: new MemoryCache()
  constructor: (@url) ->

  getCSS: (cb) ->
    if css = @cache.get(@url)
      cb(null,css)
      return

    await @loadFromRemote(defer(err,css))

    if err
      cb(err)
      return

    await @transformCSS(css,defer(err,css))

    # cache it
    @cache.put(@url,css)
    cb(null,css)

  loadFromRemote: (cb) ->
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

  transformCSS: (css,cb) ->
    lines = css.split("\n")
    await @rewriteURL(lines,defer(err,lines))
    cb(null,lines.join "\n")

  # rewrite the font URL to local
  rewriteURL: (lines,cb) ->
    fonts = []
    lines = for line in lines
      re = /.*src:.*(url\((.+)\)) /
      if m = re.exec(line)
        console.log ["match",line]
        fontURL = m[2]
        newFontURL = fontURL.replace(FONT_STATIC_ROOT,"")
        console.log ["new", newFontURL]
        fonts.push fontURL
        line2 = line.replace(/url\(.*\)/,"url(#{newFontURL})")
        console.log ["replaced", line2]
        line2
      else
        line

    console.log ["to download",fonts]

    await
      for fontURL in fonts
        gfont = new GoogleFont(fontURL)
        gfont.get(defer(err))
        if err
          console.log ["download err",err,fontPath]

    console.log ["return lines",lines]
    cb(null,lines)

app.get "/", (req,res) ->
  font = req.query.family || "Gorditas:400,700"
  fontName = font.split(":")[0]
  html = """
  <html><body>
  <h1>Grumpy wizards make toxic brew for the evil Queen and Jack.</h1>
  <link rel="stylesheet" type="text/css" href="/css?family=#{font}">
  <style>
    h1 { font-family: '#{fontName}'; }
  </style>
  </body></html>
  """
  res.end(html)

app.get '/css', (req,res) ->
  resource_url = "#{GOOGLE_FONTS_DOMAIN}#{req.originalUrl}"
  console.log "get", resource_url
  font = new GoogleFontCSS(resource_url)
  await font.getCSS(defer(err,css))
  res.end(css)

app.get /^\/fonts\/(.*)/, (req,res) ->
  resource_url = "#{FONT_STATIC_ROOT}#{req.originalUrl}"
  gfont = new GoogleFont(resource_url)
  await gfont.get(defer(err,file))

  if err
    res.status(404).end("not found: #{err}")
  else
    res.end(file)

port = 4000
console.log "listening on #{port}"
app.listen(port);