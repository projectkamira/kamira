
#
# * GET home page.
# 
exports.dashboard = (req, res) ->
  res.render 'dashboard',
    title: 'Kamira',
    js: js, css: css


exports.random = (req, res) ->
  data = []
  randomNumberNoGreaterThan = (max) ->
    Math.floor(Math.random() * max) + 1

  rightPad = (str, length, padString = '0') ->
    str = padString + str while str.length < length
    str

  for i in [1..150]
    data.push
      id: rightPad(i.toString(), 4)
      name: "Measure #{i}"
      numerator: randomNumberNoGreaterThan 75
      denominator: randomNumberNoGreaterThan 75
      population: randomNumberNoGreaterThan 75
      exceptions: randomNumberNoGreaterThan 75
      exclusions: randomNumberNoGreaterThan 75

  res.json 200, data