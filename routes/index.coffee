module.exports = (mongoose, db) ->

  Measure = require('../models/measure')(mongoose, db).model

  findAll = (callback) ->
    Measure.find (err, measures) ->
      if err? or !measures?
        res.send 'unable to find any measures', 404
      else
        callback(measures)

  @dashboard = (req, res) ->
    findAll (measures) ->
      res.render 'dashboard',
        title: 'Dashboard'
        measures: measures

  @complexity = (req, res) ->
    findAll (measures) ->
      res.render 'complexity',
        title: 'Complexity'
        measures: measures

  @financial = (req, res) ->
    findAll (measures) ->
      res.render 'financial',
        title: 'Financial Data'
        measures: measures

  return this