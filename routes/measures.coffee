Measure = require '../models/measure'

exports.search = (req, res) ->
  term = new RegExp(req.query.term, 'i')
  Measure.find {$or: [
    { name: term }
    { id: term }
  ]}, (err, measures) ->
    if err?
      res.send 'Error contacting server, please try again.', 500
    else
      switch req.get('Content-Type')
        when 'application/json'
          res.json(measures)
        else # TODO render search page, if desired
          res.json(measures)

exports.show = (req, res) ->
  id = req.params.id
  Measure.findOne {'id': id}, (err, measure) ->
    if err? or !measure?
      res.send 'unable to find that measure', 404
    else
      res.render 'measures/show', title: "Measure #{measure.id}", measure: measure
