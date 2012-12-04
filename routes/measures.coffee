module.exports = (mongoose, db) ->
  Measure = require('../models/measure')(mongoose, db).model

  @show = (req, res) ->
    id = req.params.id
    Measure.findOne {'id': id}, (err, measure) ->
      console.log 'err', err
      if err? or !measure?
        res.send 'unable to find that measure', 404
      else
        console.log 'measure', measure
        res.render 'measures/show',
          title: 'Kamira'
          measure: measure, embeddableMeasure: JSON.stringify(measure)
          js: js, css: css

  return this