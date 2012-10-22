parse = require("./parse")
tokens = require("./tokens")


class Measure
  constructor: (js) ->
    js = fs.readFileSync(pathName).toString()
    js = js.replace(/<%=.*effective_date.*%>/, 1347983662)
    js = js.replace("<%= init_js_frameworks %>", "")
    @tree = parse(js)

class Metrics
	constructor: (files) ->
		@methods = _.reduce files, (memo, file) ->
			report = jsmeter.run(content, file)
			memo.concat(report)
			,[]

	cyclomatic: (tree) ->

	complexity: (tree) ->
		