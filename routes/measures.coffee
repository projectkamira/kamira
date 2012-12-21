Measure = require '../models/measure'

exports.show = (req, res) ->
  id = req.params.id
  Measure.findOne {'id': id}, (err, measure) ->
    if err? or !measure?
      res.send 'unable to find that measure', 404
    else
      res.render 'measures/show', title: "Measure #{measure.id}", measure: measure, measures: req.measures
