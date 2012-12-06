module.exports = (mongoose, db) ->

  Measure = require('../models/measure')(mongoose, db).model

  @dashboard = (req, res) ->
    res.render 'dashboard'
      title: 'Kamira'

  @complexity = (req, res) ->
    Measure.find (err, measures) ->
      console.log 'err', err
      if err? or !measures?
        res.send 'unable to find any measures', 404
      else
        res.render 'complexity',
          title: 'Kamira'
          measures: measures

  return this