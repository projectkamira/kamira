# Module dependencies.
express = require 'express'

mongoose = require 'mongoose'

http = require 'http'
path = require 'path'
app = module.exports = express()
cons = require 'consolidate'

filters = require './filters'

mongoose.connect "mongodb://localhost/#{process.env.DATABASE or 'kamira'}", ->
  console.log "Connected to the #{mongoose.connection.name} MongoDB collection"


# CONFIGURATION
app.set 'port', process.env.PORT or 5000
app.set 'views', "#{__dirname}/views"
app.engine 'eco', cons.eco
app.set 'view engine', 'eco'

app.use require('express-partials')()
app.use express.favicon("#{__dirname}/public/favicon.ico")
app.use express.bodyParser()
app.use express.methodOverride()
app.use require('connect-assets')()
app.use express.static(path.join(__dirname, 'public'))
app.use express.errorHandler()
app.use filters.setupMeasures

app.configure 'development', ->
  app.use express.logger('dev')

app.configure 'production', ->
  app.use express.logger(express.logger.default + ' ":response-time ms"')

app.use app.router


# ROUTES
home = require './routes'
measure = require './routes/measures'

app.get     '/',              home.dashboard
app.get     '/complexity',    home.complexity
app.get     '/financial',     home.financial
app.get     '/help',          home.help
app.get     '/about',         home.about
app.get     '/measures/:id',  measure.show

# START ME UP
http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port #{app.get('port')}"
