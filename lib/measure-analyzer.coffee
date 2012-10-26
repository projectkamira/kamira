_ = require 'underscore'
parse = require('../vendor/parse').make_parse()
tokens = require '../vendor/tokens'
jsmeter = require('jsmeter-fixed').jsmeter

class Analysis
  constructor: (@js, @functionList) ->
  extract: (name) ->
    _.find @functionList, (func) -> func.shortName.split('.').pop() is name
  findFunction: (name, tree, selector, parent) ->
    found = null
    if _.isArray(tree)
      found ?= @findFunction name, branch, selector, tree for branch in tree
    return unless tree?
    if selector(parent, tree, name)
      found ?= parent.second
    else
      found ?= @findFunction(name, tree.first, selector, tree) if tree.first?
      found ?= @findFunction(name, tree.second, selector, tree) if tree.second?
    found
  cyclomatic: (result, context) ->
    context.nodes += result.nodes
    context.edges += result.edges
    context.exits += result.exits
    return context
  analyze: (tree, calcFunction, context = {edges: 0, nodes: 0, exits: 0}) ->
    tree = [tree] unless _.isArray(tree)
    _.reduce tree, (totals, branch) =>
      if branch.arity in ["literal", "name"]
        result = @extract(branch.value)
        context = calcFunction(result, context) if result?
      @analyze(branch.first, calcFunction, totals) if branch.first?
      @analyze(branch.second, calcFunction, totals) if branch.second?
      return totals
    , context
    return context

class StageOneAnalysis extends Analysis
  complexityFor: (funcName) ->
    func = @findFunction funcName, @js, (parent, tree, name) -> tree.value is name
    result = @analyze(func, @cyclomatic)
    score = result.edges - result.nodes + result.exits
    Math.max(1, score)

  complexity: ->
    numerator:   @complexityFor('numerator')
    denominator: @complexityFor('denominator')
    population:  @complexityFor('population')
    exclusion:   @complexityFor('exclusion')

class StageTwoAnalysis extends Analysis
  complexityFor: (funcName) ->
    func = @findFunction funcName, @js,  (parent, tree, name) ->
      parent?.value is "=" and "#{tree.first?.value}.#{tree.second?.value}" is name
    result = @analyze(func, @cyclomatic)
    score = result.edges - result.nodes + result.exits
    Math.max(1, score)

  complexity: ->
    numerator:   @complexityFor('hqmfjs.NUMER')
    denominator: @complexityFor('hqmfjs.DENOM')
    population:  @complexityFor('hqmfjs.IPP')
    exclusions:  @complexityFor('hqmfjs.DENEX')
    exceptions:  @complexityFor('hqmfjs.EXCEP')

module.exports = class MeasureAnalyzer
  constructor: (utils, options = {stage: 'stage2'}) ->
    # @Analysis = switch options.stage
    #   when 'stage1' then StageOneAnalysis
    #   when 'stage2' then StageTwoAnalysis
    #   default: throw "unknown stage: #{options.stage}"
    if options.stage is 'stage1'
      @Analysis = StageOneAnalysis
    else if options.stage is 'stage2'
      @Analysis = StageTwoAnalysis
    else
      throw "unknown stage: #{options.stage}"
    tokens.setup()
    @utilsResults = []
    for own name, content of utils
      @utilsResults.push jsmeter.run(content, name)...

  analyze: (js, label) ->
    tree = parse(js)
    measure = jsmeter.run(js, label)
    complexitySet = _.union(@utilsResults, measure)

    new @Analysis(tree, complexitySet)

      # report = metrics.report(tree, complexitySet)

      # report["name"] = json.name
      # jsonId = if measure.sub_id? then "#{measure.nqf_id}#{measure.sub_id}" else measure.nqf_id
      # report["id"] = jsonId
      # console.log(jsonId)
      # report

    # return an Analysis object from which you can call #complexity() or #halstead() on