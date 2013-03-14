Measure = require '../models/measure'
Cost = require '../models/cost'

_ = require 'underscore'

exports.show = (req, res) ->
  id = req.params.id
  Measure.findOne {'_id': id}, (err, measure) ->
    if err? or !measure?
      res.send 'unable to find that measure', 404
    else
      Cost.find { oid: { $in: measure.oids } }, (err, costs) ->

        # FIXME: We want a sensible way to combine cost information
        # with the measure, either by writing it as a collection on
        # the measure or otherwise on the backend; this will server to
        # start POCing on the front end

        # Little function to map costs onto criteria
        criteriaWithCost = (criteria) ->
          _(criteria).map (ct) ->
            cost = _(costs).find (c) -> c.oid == ct.oid
            _(ct).extend(cost?._doc)

        # Hijack toJSON to wedge in our additional content
        jsonObject = measure.toJSON()
        jsonObject.numeratorCosts = criteriaWithCost(measure.numeratorCriteria)
        jsonObject.denominatorCosts = criteriaWithCost(measure.denominatorCriteria)
        jsonObject.populationCosts = criteriaWithCost(measure.populationCriteria)
        jsonObject.exclusionsCosts = criteriaWithCost(measure.exclusionsCriteria)
        jsonObject.exceptionsCosts = criteriaWithCost(measure.exceptionsCriteria)
        measure.toJSON = -> jsonObject

        res.render 'measures/show', title: "Measure #{measure.id}", measure: measure, measures: req.measures
