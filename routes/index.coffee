module.exports = (mongoose, db) ->

  Measure = require('../models/measure')(mongoose, db).model

  @dashboard = (req, res) ->
    res.render 'dashboard'
      title: 'Kamira'
      js: js, css: css

  @complexity = (req, res) ->
    Measure.find (err, measures) ->
      console.log 'err', err
      if err? or !measures?
        res.send 'unable to find that measure', 404
      else
        res.render 'complexity',
          title: 'Kamira'
          measures: measures, embeddableMeasures: JSON.stringify(measures)
          js: js, css: css

  return this