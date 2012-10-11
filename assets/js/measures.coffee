window.measureScores = {}

randomNumberNoGreaterThan = (max) ->
  Math.floor(Math.random() * max) + 1

rightPad = (str, length, padString = '0') ->
  str = padString + str while str.length < length
  str

for i in [1..150]
  window.measureScores[rightPad i.toString(), 4] =
    name: "Measure #{i}"
    numerator: randomNumberNoGreaterThan 350
    denominator: randomNumberNoGreaterThan 350
    population: randomNumberNoGreaterThan 350
    exceptions: randomNumberNoGreaterThan 350
    exclusions: randomNumberNoGreaterThan 350
    exclusions2: randomNumberNoGreaterThan 350