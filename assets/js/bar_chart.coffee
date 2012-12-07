window.Kamira ||= {};
window.Kamira.BarChart = (target, data, options = {}) ->

  w = options.w or options.width  or 200
  h = options.h or options.height or 125

  labelWidth = options.labelWidth or 0
  labelClass = options.labelClass

  barWeight = options.barWeight or 0.9
  barHeight = h * barWeight / data.length
  barSpace = h * (1 - barWeight) / data.length

  showValues = options.showValues or false
  valueWidth = if showValues then 20 else 0

  barOffset = labelWidth + valueWidth + 5

  xScale = d3.scale.linear()
    .domain([0, d3.max(data, (d) -> d.value)])
    .range([0, w - barOffset])

  svg = d3.select(target).append('svg').attr('width', w).attr('height', h)

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
    .attr('x1', barOffset + 0.5)
    .attr('y1', 0)
    .attr('x2', barOffset + 0.5)
    .attr('y2', h)
    .attr('stroke', '#BBB')

  svg.selectAll('rect')
    .data(data)
    .enter()
    .append('rect')
    .attr('x', barOffset)
    .attr('y', (d, i) -> i * (barHeight + barSpace) + barSpace/2)
    .attr('width', (d) -> xScale(d.value))
    .attr('height', barHeight)
    .attr('fill', (d) -> d.color)
