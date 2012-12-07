module.exports = (mongoose, db) ->

  Measure = require('../models/measure')(mongoose, db).model

  @dashboard = (req, res) ->
    # TODO refactor extract method
    Measure.find (err, measures) ->
      console.log 'err', err
      if err? or !measures?
        res.send 'unable to find any measures', 404
      else
        res.render 'dashboard',
          title: 'Dashboard'
          measures: measures

  @complexity = (req, res) ->
    Measure.find (err, measures) ->
      console.log 'err', err
      if err? or !measures?
        res.send 'unable to find any measures', 404
      else
        res.render 'complexity',
          title: 'Complexity'
          measures: measures

  return this