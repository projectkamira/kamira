Measure = require './models/measure'

# For all requests, load all measures and make available as req.measures
exports.setupMeasures = (req, res, next) ->
  Measure.find().sort('nqf_id sub_id').exec (err, measures) ->
    if err? or !measures?
      res.send err + 'unable to find any measures', 404
    else
      req.measures = measures
      next()
