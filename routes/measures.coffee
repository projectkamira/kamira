module.exports = (mongoose, db) ->
  Measure = require('../models/measure')(mongoose, db).model

  @show = (req, res) ->
    id = req.params.id
    Measure.findOne {'id': id}, 'id', (err, measure) ->
      console.log 'err', err
      console.log 'measure', measure
      res.render 'measures/show',
        title: 'Kamira'
        measure: measure
        js: js, css: css

  return this