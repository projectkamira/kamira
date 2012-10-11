window.SpiderChart = (src, target, options = {}) ->
  w = options.w or options.width  or 350
  h = options.h or options.height or 200
  margin = options.m or options.margin or 50

  chartHelper = 
    population:
      label: 'Initial Population'
    exclusions:
      label: 'Exclusion'
    exceptions:
      label: 'Exception'
    numerator:
      label: 'Numerator'
    denominator:
      label: 'Denominator'

  # translate 0 < i < sizeof(chartHelper) to angle
  angle = (i) -> i * (2*Math.PI / d3.keys(chartHelper).length) + Math.PI/2

  d3.json src, (json) ->
    chart = d3.select target
    measures = d3.nest().entries(json)
    outerRadius = d3.max measures.map((measure) -> d3.max(d3.keys(chartHelper), (key) -> measure[key]))

    qualityRange =
      simple: 10
      nominal: 20
      complex: 50
      untestable: 62
    color = (val) ->
      if val > qualityRange.untestable
        'untestable'
      else
        for cssClass, range of qualityRange
          return cssClass if val <= range

    DOMAIN_OFFSET = 10 # logarithmic domain can't start at 0, because log(0) is Infinity
    _scale = d3.scale.linear().domain([0, qualityRange.untestable+DOMAIN_OFFSET]).range([0, h/2])
    window.scale = scale = (n) -> _scale(Math.min(n, qualityRange.untestable) + DOMAIN_OFFSET)
    scale[key] = prop for own key, prop of _scale
    line = d3.svg.line()
      .interpolate('cardinal-closed')
      .tension(0.75)
      .x (d, i) ->
        Math.cos(angle(i)) * scale(d)
      .y (d, i) ->
        -Math.sin(angle(i)) * scale(d)
      

    # does it make sense to use data(json).enter() ?
    for mData in json
      # append header
      div = chart.append('div').attr('class','chart')
      div.append('h3').text "Measure #{mData.id}: #{mData.name}"
      # start in on svg
      parent = div.append('svg').attr('width', w+margin).attr('height', h+margin)
        .append('svg:g').attr('transform', "translate(#{(w+margin)/2}, #{(h+margin)/2})")

      parent.append('svg:circle').attr('r', scale(0)).attr('class', 'origin')
      for cssClass, range of qualityRange
        parent.append('svg:circle').attr('r', scale(range)).attr('class', "#{cssClass} bullseye")

      for n in d3.values(qualityRange)
        parent.append('svg:text').attr('class', 'bullseye-label')
          .attr('y', scale(n) - 2).attr('text-anchor', 'middle')
          .text("#{n}#{if n is qualityRange.untestable then '+' else ''}")

      # draw line across all data points
      nums = for key of chartHelper
        mData[key]
      parent.selectAll('path.spider')
        .data([nums]).enter()
        .append('svg:path')
        .attr('class', "spider #{color(d3.mean(nums))}")
        .attr 'd', (d) -> "#{line(d)}Z"
      # iterate through axes
      for i, helper of d3.entries(chartHelper)
        i = parseInt i # remember, for some reason i is a character here, not an integer!
        group = parent.append('svg:g').attr('transform', "rotate(#{-(angle(i) * 180/Math.PI)})")
        # label
        group.append('svg:text').attr('class', "label").text(helper.value.label)
          .attr('x', h/2 + 13).attr('y', 0)
          .attr('text-anchor', 'middle')
          .attr 'transform', ->
            x = d3.select(@).attr 'x'
            y = d3.select(@).attr 'y'
            "rotate(#{if i in [2..3] then -90 else 90} #{x} #{y})"
        # draw axis
        group.call(d3.svg.axis().tickValues(0).tickSize(1).scale(scale))
        #   .selectAll('text').attr('text-anchor', 'middle')
        #   .attr 'transform', (d) ->
        #     x = d3.select(@).attr 'x'
        #     y = d3.select(@).attr 'y'
        #     "rotate(#{angle(i) * 180 / Math.PI} #{x} #{y})"
        # circle
        group.append('svg:circle').attr('class', "#{helper.key} #{color(mData[helper.key])}").attr('r', 6)
          .attr('cx', scale(mData[helper.key])).attr('value', mData[helper.key])
        group.append('svg:text').attr('class', 'value').text(mData[helper.key])
          .attr('x', scale(mData[helper.key]) + 10).attr('y', 10)
          .attr 'transform', (d) ->
            x = d3.select(@).attr 'x'
            y = d3.select(@).attr 'y'
            "rotate(#{angle(i) * 180 / Math.PI} #{x} #{y})"

