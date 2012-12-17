#= require 'd3.v2'
#= require 'bootstrap-typeahead'

$ ->
  $('.measure-lookup .search-query').typeahead
    source: (query, process) ->
      $.getJSON '/search', {term: query}, (results) -> process(results)
    matcher: (item) -> yes # taken care of by source
    # TODO decide upon sort algorithm (below is heavily based on Twitter Bootstrap's)
    sorter: (items) ->
      beginswith = []
      caseSensitive = []
      caseInsensitive = []
      while item = items.shift()
        json = JSON.stringify(item) # need to convert to string, as this will be saved to the DOM
        unless item.name.toLowerCase().indexOf(@query.toLowerCase())
          beginswith.push(json)
        else if ~item.name.indexOf(this.query)
          caseSensitive.push(json)
        else
          caseInsensitive.push(json)
      beginswith.concat(caseSensitive, caseInsensitive)
    highlighter: (item) ->
      item = JSON.parse(item)
      query = @query.replace /[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&'
      display = "#{item.id}: #{item.name}"
      display.replace new RegExp("(#{query})", 'ig'), ($1, match) -> "<strong>#{match}</strong>"
    updater: (item) ->
      item = JSON.parse(item)
      window.location = "/measures/#{item.id}"
      return '' # otherwise value will stay in search bar
