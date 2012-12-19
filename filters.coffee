Measure = require './models/measure'

# For all requests, load all measures and make available as req.measures
exports.setupMeasures = (req, res, next) ->
  Measure.find (err, measures) ->
    if err? or !measures?
      res.send 'unable to find any measures', 404
    else
      req.measures = measures
      next()
