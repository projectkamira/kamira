Measure = require '../models/measure'
Cost = require '../models/cost'

exports.show = (req, res) ->
  id = req.params.id
  Measure.findOne {'_id': id}, (err, measure) ->
    if err? or !measure?
      res.send 'unable to find that measure', 404
    else
      Cost.find { oid: { $in: measure.oids } }, (err, costs) ->
        res.render 'measures/show', title: "Measure #{measure.id}", measure: measure, measures: req.measures, costs: costs
