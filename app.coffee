# Module dependencies.
express = require 'express'

mongoose = require 'mongoose'

http = require 'http'
path = require 'path'
app = module.exports = express()
cons = require 'consolidate'

console.log 'creating connection'
db = mongoose.createConnection 'mongodb://localhost/kamira'

# CONFIGURATION
app.configure ->
  app.set 'port', process.env.PORT or 5000
  app.set 'views', "#{__dirname}/views"
  app.engine 'eco', cons.eco
  app.set 'view engine', 'eco'
  app.use require('express-partials')()
  app.use express.favicon("#{__dirname}/public/favicon.ico")
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require('connect-assets')()
  app.use express.static(path.join(__dirname, 'public'))

app.configure 'development', -> app.use express.errorHandler()

# ROUTES
home = require('./routes')(mongoose, db)
measure = require('./routes/measures')(mongoose, db)

app.get     '/',              home.dashboard
app.get     '/complexity',    home.complexity
# app.get     '/measures',      measure.index
app.get     '/measures/:id',  measure.show
# app.post    '/measures/:id',  measure.create
# app.put     '/measures/:id',  measure.update
# app.delete  '/measures/:id',  measure.delete

# START ME UP
http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port #{app.get('port')}"
