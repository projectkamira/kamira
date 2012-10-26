# Module dependencies.
express = require "express"
routes = require "./routes"
# user = require "./routes/user"
http = require "http"
path = require "path"
app = express()

app.configure ->
  app.set "port", process.env.PORT or 5000
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "hjs"
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require('connect-assets')()
  app.use express.static(path.join(__dirname, "public"))

app.configure "development", -> app.use express.errorHandler()

app.get "/", routes.index
app.get '/random.json', routes.random
# app.get "/users", user.list
http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port #{app.get('port')}"