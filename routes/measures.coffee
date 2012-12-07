module.exports = (mongoose, db) ->
  Measure = require('../models/measure')(mongoose, db).model

  @show = (req, res) ->
    id = req.params.id
    Measure.findOne {'id': id}, (err, measure) ->
      if err? or !measure?
        res.send 'unable to find that measure', 404
      else
        res.render 'measures/show', title: "Measure #{measure.id}", measure: measure

  return this