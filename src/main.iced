express = require('express')
app = express()


# http://fonts.googleapis.com/css?family=Signika+Negative:300
GOOGLE_FONTS_DOMAIN = "http://fonts.googleapis.com"

app.get '/css', (req,res) ->
  resource_url = "#{GOOGLE_FONTS_DOMAIN}/css?#{req.query}"
  console.log "get", resource_url
  res.end("ok")

app.listen(4000);