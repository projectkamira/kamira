fs = require("fs")
path = require('path')
jsmeter = require("jsmeter-fixed").jsmeter
_ = require("underscore")
exports.loadUtils = (dir) ->
  util_methods = []
  files = fs.readdirSync dir
  for file in files
    continue if path.extname(file) != ".js"
    util_path = path.join dir, file
    buffer = fs.readFileSync(util_path)
    result = jsmeter.run(buffer.toString())
    util_methods = _.union(util_methods, result)
  return util_methods

exports.extract = (name, results) ->
  _.find results, (func) -> func.shortName.split(".").pop() == name
exports.findFunction = (name, tree, parent) ->
  found = null
  if _.isArray(tree)
    found ?= exports.findFunction name, branch, tree for branch in tree
  return unless tree?
  if parent && tree.first? && tree.second? && parent.value = "=" && [tree.first.value, tree.second.value].join(".") == name
    found ?= parent.second
  else
    found ?= exports.findFunction(name, tree.first, tree) if tree.first?
    found ?= exports.findFunction(name, tree.second,tree) if tree.second?
  return found
exports.analyze = (tree, functionList, context) ->
  context ?= {edges: 0, nodes: 0, exits: 0}
  tree = if _.isArray(tree) then tree else [tree]
  _.reduce tree, (totals, memo) ->
    if memo.arity == "literal" || memo.arity == "name"
      context = exports.calculate(functionList, memo.value, context)
    exports.analyze(memo.first, functionList, totals) if memo.first?
    exports.analyze(memo.second, functionList, totals) if memo.second?
    return totals
  , context
  return context
exports.calculate = (results, method, context) ->
  result = exports.extract(method, results)
  return context unless result?
  context.nodes += result.nodes
  context.edges += result.edges
  context.exits += result.exits
  return context
exports.complexity = (funcName, js, set) ->
  func = exports.findFunction(funcName, js)
  result = exports.analyze(func, set)
  score = result.edges - result.nodes + result.exits
  if score == 0 then 1 else score
exports.report = (js, functionList) ->
    numerator : exports.complexity("hqmfjs.NUMER", js, functionList)
    denominator : exports.complexity("hqmfjs.DENOM", js, functionList)
    population : exports.complexity("hqmfjs.IPP", js, functionList)
    exclusions : exports.complexity("hqmfjs.EXCL", js, functionList)
    exceptions : exports.complexity("hqmfjs.DENEXCEP", js, functionList)
  
