window.Kamira ||= {}

# Draw a measure summary bar chart using D3
#
#   target: selector indicating where chart should be drawn
#
#   data: key value pairs indicating label and rating; rating is
#         converted to value and is used as class name (which sets color)

window.Kamira.MeasureBarChart = (measure, target) ->
  valueLookup = poor: 1, nominal: 2, good: 3
  values = ({ value: valueLookup[rating], class: rating, label: label } for label, rating of measure)
  console.log values
  Kamira.BarChart(values, target, w: 220, h: 90, barWeight: 0.8, labelWidth: 95, divideAt: 1, labelClass: 'smaller', labelsRight: true)


# Draw a summary horizontal bar chart using D3
#
#   measures: array of measures to aggregate
#
#   target: selector indicating where chart should be drawn
#
#   options:
#     category: summary type; complexity, availability, financial or not set for overall
#     categoryMapping: a hash lookup table convertinga categories ratings to good, nominal and poor
#
# Note: the label is automatically capitalized; the pre-capitalized
# version is used as the class name

window.Kamira.SummaryBarChart = (measures, target, options = {}) ->
  ratings = {}
  for measure in measures
    ratingBase = if options.category then measure[options.category] else measure
    ratingCategory = ratingBase.rating
    ratingCategory = options.categoryMapping[ratingCategory] if options.categoryMapping
    ratings[ratingCategory] ||= 0
    ratings[ratingCategory] += 1
  capitalize = (string) -> string.charAt(0).toUpperCase() + string.substring(1)
  values = ({ value: ratings[category], class: category, label: capitalize(category)} for category in ['good', 'nominal', 'poor'])
  Kamira.BarChart(values, target, w: 180, h: 100, showValues: true, barWeight: 0.5, labelWidth: 75, labelClass: 'strong')


# Draw a general horizontal bar chart using D3; if possible prefer one
# of the more specific bar chart creators
#
#   data: array of data elements; each element is an object:
#     value: numeric value
#     class: class to use for this bar (an svg rect)
#     label: label to use for thar bar
# 
#   target: selector indicating where chart should be drawn
# 
#   options:
#     w or width: width in pixels
#     h or height: width in pixels
#     labelWidth: width of the label space, in pixels
#     labelClass: class of the label, in pixels
#     barWeight: thickness of bar, ranging from 0.0 to 1.0
#     divideAt: dotted line divisors appear at every divideAt interval
#     labelsRight: labels are right justified

window.Kamira.BarChart = (data, target, options = {}) ->

  w = options.w or options.width  or 200
  h = options.h or options.height or 125

  labelWidth = options.labelWidth or 0
  labelClass = options.labelClass

  barWeight = options.barWeight or 0.9
  barHeight = h * barWeight / data.length
  barSpace = h * (1 - barWeight) / data.length

  divideAt = options.divideAt
  labelsRight = options.labelsRight

  showValues = options.showValues or false
  valueWidth = if showValues then 20 else 0

  barOffset = labelWidth + valueWidth + 5

  domainMax = d3.max(data, (d) -> d.value)

  window.xScale = d3.scale.linear()
    .domain([0, domainMax])
    .range([0, w - barOffset])

  svg = d3.select(target).append('svg').attr('width', w).attr('height', h).attr('class', 'bar-chart')

  if labelWidth
    svg.selectAll("text.#{labelClass or 'label'}")
      .data(data)
      .enter()
      .append('text')
      .text((d) -> d.label)
      .attr('x', 0)
      .attr('y', (d, i) -> i * (barHeight + barSpace) + barHeight/2 + barSpace/2)
      .attr('dy', '0.5em')
      .attr('class', labelClass)
      .attr('text-anchor', if labelsRight then 'end' else 'start')
      .attr('dx', if labelsRight then labelWidth else 0)

  if showValues
    svg.selectAll('text.value')
      .data(data)
      .enter()
      .append('text')
      .text((d) -> "#{d.value}")
      .attr('x', labelWidth)
      .attr('y', (d, i) -> i * (barHeight + barSpace) + barHeight/2 + barSpace/2)
      .attr('dy', '0.5em')

  svg.append('line')
    .attr('x1', barOffset - 0.5)
    .attr('y1', 0)
    .attr('x2', barOffset - 0.5)
    .attr('y2', h)
    .attr('stroke', '#AAA')

  svg.selectAll('rect')
    .data(data)
    .enter()
    .append('rect')
    .attr('x', barOffset)
    .attr('y', (d, i) -> i * (barHeight + barSpace) + barSpace/2)
    .attr('width', (d) -> xScale(d.value))
    .attr('height', barHeight)
    .attr('class', (d) -> d.class)

  if divideAt
    for offset in [1..domainMax] by divideAt
      svg.append('line')
        .attr('x1', barOffset + xScale(offset) - 0.5)
        .attr('y1', 0)
        .attr('x2', barOffset + xScale(offset) - 0.5)
        .attr('y2', h)
        .attr('stroke', '#999')
        .attr('stroke-dasharray', '4,4')
