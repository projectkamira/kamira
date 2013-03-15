window.Kamira ||= {};

window.Kamira.BoxScale = (domain, target, options = {}) ->
  width       = options.width       or 600
  height      = options.height      or 35
  margin      = options.margin      or 8
  cornerRad   = options.cornerRad   or 2
  svgAttrs    = options.svgAttrs    or {}
  quality     = options.quality     or ''
  textHeight  = options.textHeight  or 15

  svg = d3.selectAll(target).append('svg').attr('height', height + textHeight)
  svg.attr(k, v) for k, v of svgAttrs

  scale = d3.scale.linear().domain(domain).range([margin, width - margin])

  svg.call d3.svg.axis().ticks(15).scale(scale).tickFormat (n) -> "$#{d3.format(',')(n)}"


window.Kamira.BoxPlot = (data, target, options = {}) ->
  width       = options.width       or 600
  height      = options.height      or 35
  margin      = options.margin      or 8
  cornerRad   = options.cornerRad   or 2
  svgAttrs    = options.svgAttrs    or {}
  quality     = options.quality     or ''
  textHeight  = options.textHeight  or 15
  domain      = options.domain      or [data.min, data.max]

  svg = d3.select(target).append('svg').attr('height', height + textHeight)
  svg.attr(k, v) for k, v of svgAttrs

  window.scale = scale = d3.scale.linear().domain(domain).range([margin, width - margin])

  # only display box plot when we have more than 15px worth of data to show, otherwise just show median
  if scale(data.max) - scale(data.min) > 0
    svg.append('line')
      .attr('class', 'whisker')
      .attr('x1', scale(data.min)).attr('x2', scale(data.min))
      .attr('y1', margin).attr('y2', height - margin)
    svg.append('line')
      .attr('class', 'whisker')
      .attr('x1', scale(data.max)).attr('x2', scale(data.max))
      .attr('y1', margin).attr('y2', height - margin)

    svg.append('line')
      .attr('class', 'center')
      .attr('x1', scale(data.min)).attr('x2', scale(data.max))
      .attr('y1', height/2).attr('y2', height/2)

    svg.append('rect')
      .attr('class', "box #{quality}")
      .attr('x', scale(data.firstQuartile)).attr('y', margin)
      .attr('rx', cornerRad).attr('ry', cornerRad)
      .attr('width', scale(data.thirdQuartile) - scale(data.firstQuartile))
      .attr('height', height - margin*2)

    labels = {}
    for key, val of data
      if key in ['min', 'max', 'firstQuartile', 'thirdQuartile']
        svg.append('rect')
          .attr('class', 'mouseover').attr('data-field', key)
          .attr('x', scale(val) - 5).attr('y', margin)
          .attr('width', 10).attr('height', height - margin*2 + textHeight)
          .on 'mouseover', ->
            key = d3.select(this).attr('data-field')
            labels[key].style 'visibility', 'visible'
          .on 'mouseout', ->
            key = d3.select(this).attr('data-field')
            labels[key].style 'visibility', 'hidden'

        labels[key] = svg.append('text').text("$#{d3.format(',')(val)}")
          .attr('class', "#{key} #{quality}").style('visibility', 'hidden')
          .attr('x', scale(val))
          .attr('y', height).attr('dy', textHeight / 2)

  svg.append('text').text("$#{d3.format(',')(data.median)}")
    .attr('class', "median #{quality}")
    .attr('x', scale(data.median))
    .attr('y', height).attr('dy', textHeight / 2)

  svg.append('line')
    .attr('class', 'median')
    .attr('x1', scale(data.median)).attr('x2', scale(data.median))
    .attr('y1', margin).attr('y2', height - margin)

