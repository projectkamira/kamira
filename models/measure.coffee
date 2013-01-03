mongoose = require 'mongoose'

measureSchema = new mongoose.Schema
  id: String
  name: String
  complexity:
    numerator:    Number
    denominator:  Number
    population:   Number
    exclusions:   Number
    exceptions:   Number

# Calculate numerator costs of a measure; this is an experimental first pass and will likely change substantially
# PWKFIX: Pass costs in for now, eventually grab them from DB; they are a hash of objects on OID with min/max keys
measureSchema.methods.calculateNumeratorCosts = (costs)->

  # PWKFIX: Need to handle
  #   1) repeating items (just look at specific occurrances? What if the different ones would calc differently?)
  #   2) items that don't have costs (just store 0 cost for those? Probably should skip ie characteristics)
  #   3) negations
  #   4) temporal references that contain items with costs
  #   5) temporal references that appear in denominator or population, and so shouldn't be calculated
  #   6) counts
  #   7) grouping references (which can contain conjunctions)
  #   8) real error handling rather than console logging
  # We'll want to calculate a bunch of costs by hand to validate

  # Note: this can be as complicated as we'd like; what if numerator has multiple
  # options, which have different preconditions that appear in the population?

  # Break down numerator into codes via recursive descent, use conjunctions
  # (and/or) to drive cost combination calculations, apply costs

  alreadySeen = {} # Track the costs we've already included in the calculation elsewhere so we don't double count

  # Look up the cost of a single item, without recursing; returns null if we can't look up or if already seen
  lookupSingle = (item) ->

    return null if item.type in ['characteristic', 'conditions']

    return null unless item.code_list_id?

    if item.specific_occurrence?
      return null if alreadySeen[item.code_list_id]?[item.specific_occurrence]?
      alreadySeen[item.code_list_id] = {}
      alreadySeen[item.code_list_id][item.specific_occurrence] = true

    return costs[item.code_list_id] if costs[item.code_list_id]
        
    console.log "Need cost information for: #{item.title} [#{item.code_list_id}]"
    return null

  # Calculate the cost of a tree of items recursively
  calculateRecursive = (item) ->

    if item.conjunction?

      subResults = (calculateRecursive(i) for i in item.items)
      subResults = (r for r in subResults when r) # Filter out nulls
      if subResults.length > 0
        switch item.conjunction
          when 'or'
            # For OR min is the min of all mins, and max is the *min* of all maxes
            min: Math.min (r.min for r in subResults)...
            max: Math.min (r.max for r in subResults)...
          when 'and'
            # For AND min is the sum of all mins, and max is the sum of all maxes
            min: (r.min for r in subResults).reduce (x, y) -> x + y
            max: (r.max for r in subResults).reduce (x, y) -> x + y
          else
            console.log "ERROR: unknown conjunction"
            null

    else if item.code_list_id?

      # PWKFIX: Can temporal references have conjunctions?
      # PWKFIX: Assumes temporal references can contain items that don't appear elsewhere

      # For now simply sum the costs of all temporal references with the parent item
      items = [item]
      if item.temporal_references?
        items.push(tr.reference) for tr in item.temporal_references when tr.reference.code_list_id
      itemCosts = (lookupSingle(i) for i in items)
      itemCosts = (ic for ic in itemCosts when ic) # Prune out nulls
      if itemCosts.length > 0
        itemCosts.reduce (x, y) ->
          min: x.min + y.min
          max: x.max + y.max

    else
      console.log "Unrecognized item:"
      console.log item
      null

  # Pre-populate the list of already seen codes with codes from the denominator and
  # population, which we shouldn't include in the cost calculation
  calculateRecursive(@_doc.population)
  calculateRecursive(@_doc.denominator)
    
  # PWKFIX Remove _doc when schema updates are checked in
  calculateRecursive(@_doc.numerator)

# Computed complexity rating
# PWKFIX: This duplicates rating scale in spider-chart.js; refactor!
measureSchema.virtual('complexity.rating').get ->
  worst = Math.max(@complexity.numerator, @complexity.denominator, @complexity.population, @complexity.exclusions, @complexity.exceptions)
  return 'simple' if worst <= 10
  return 'nominal' if worst <= 20
  return 'complex' if worst <= 50
  return 'untestable'

# Throw some "data" out for now, just to test graph population
ratings = ['good', 'nominal', 'poor']
randomRating = -> ratings[Math.floor(Math.random() * 3)]
measureSchema.virtual('availability.rating').get -> @availabilityRating ||= randomRating()
measureSchema.virtual('financial.rating').get -> @financialRating ||= randomRating()
measureSchema.virtual('rating').get ->
  complexity = switch @complexity.rating
    when 'simple' then 0
    when 'nominal' then 1
    when 'complex' then 2
    when 'untestable' then 2
  availability = ratings.indexOf(@availability.rating)
  financial = ratings.indexOf(@financial.rating)
  ratings[Math.round((complexity + availability + financial) / 3)]

measureSchema.set('toJSON', { virtuals: true })

module.exports = mongoose.model 'Measure', measureSchema
