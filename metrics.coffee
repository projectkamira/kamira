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
  _.find results, (func) ->
    func.shortName.split(".").pop() == name
exports.findFunction = (name, tree, selector, parent) ->
  found = null
  if _.isArray(tree)
    found ?= exports.findFunction name, branch, selector, tree for branch in tree
  return unless tree?
  if selector(parent, tree, name)
    found ?= parent.second
  else
    found ?= exports.findFunction(name, tree.first, selector, tree) if tree.first?
    found ?= exports.findFunction(name, tree.second, selector, tree) if tree.second?
  return found
exports.analyze = (tree, functionList, calcFunction, context) ->
  context ?= {edges: 0, nodes: 0, exits: 0}
  tree = if _.isArray(tree) then tree else [tree]
  _.reduce tree, (totals, branch) ->
    if branch.arity == "literal" || branch.arity == "name"
      result = exports.extract(branch.value, functionList)  
      context = if result then calcFunction(result, context) else context
    exports.analyze(branch.first, functionList, calcFunction, totals) if branch.first?
    exports.analyze(branch.second, functionList, calcFunction, totals) if branch.second?
    return totals
  , context
  return context
exports.cyclomatic = (result, context) ->
  context.nodes += result.nodes
  context.edges += result.edges
  context.exits += result.exits
  return context
exports.complexity = (funcName, js, set, calcFunction) ->
  calcFunction ?= exports.cyclomatic
  func = exports.findFunction funcName, js,  (parent, tree, name) ->
    return parent && tree.first? && tree.second? && parent.value = "=" && [tree.first.value, tree.second.value].join(".") == name
  result = exports.analyze(func, set, calcFunction)
  score = result.edges - result.nodes + result.exits
  if score == 0 then 1 else score
exports.complexity1 = (funcName, js, set, calcFunction) ->
  func = exports.findFunction funcName, js, (parent, tree, name) ->
    return tree.value == name
  
  return exports.analyze(func, set, exports.cyclomatic) 
exports.report = (js, functionList) ->
    numerator : exports.complexity("hqmfjs.NUMER", js, functionList)
    denominator : exports.complexity("hqmfjs.DENOM", js, functionList)
    population : exports.complexity("hqmfjs.IPP", js, functionList)
    exclusions : exports.complexity("hqmfjs.DENEX", js, functionList)
    exceptions : exports.complexity("hqmfjs.EXCEP", js, functionList)
exports.report1 = (js, functionList) ->
    return [exports.complexity1("numerator", js, functionList),
    exports.complexity1("denominator", js, functionList),
    exports.complexity1("population", js, functionList),
    exports.complexity1("exclusion", js, functionList)]

