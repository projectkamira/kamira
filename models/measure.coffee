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
measureSchema.methods.calculateNumeratorCosts = (costs, options = {}) ->

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

  indent = 0
  
  logger = (msg) ->
    return unless options.logging
    prefix =  (new Array(indent)).join("|  ")
    if typeof(msg) == 'object' || typeof(msg) == 'array' 
      console.log(msg)
    else
      console.log("#{prefix}#{msg}")

  # Track details on what we do and do not have cost information for
  costAvailabilityDetails = {}

  alreadySeen = {} # Track the costs we've already included in the calculation elsewhere so we don't double count

  filterTypes = {
                "transfer_to":[""], 
                "transefer_from": [""],
                "risk_category_assessment": [""], 
                "functional_status_performed" : ["performed"], 
                "symptom_assessed" : [""] ,
                "intervention" :["performed", ""], 
                "substance" : ["administered"], 
                "device" :["applied"], 
                "laboratory_test" : ["performed"], 
                "physical_exam" :["performed",""],
                "medication" : ["administered",""], 
                "diagnostic_study" :["performed", ""], 
                "procedure" :["performed",""], 
                "encounter" : ["performed",""]  
                }
  
  filterItem = (item) ->
    definition = filterTypes[item.definition]
    if (item.negated? || !definition || definition.indexOf(item.status) == -1)
      logger "Item NOT IN filter list:  #{item.title} (#{item.definition}/#{item.status}/#{definition})"
      return false
    else
      logger "Item IN filter list: #{item.title} (#{item.definition}/#{item.status}/#{definition})"
      return  true

  # RD: Look up the cost of a single item, without recursing; returns null if we can't look up or if already seen
  # RD : If the item is negated need to return null? not doing something is free
  lookupSingle = (item) ->

    # RD: need function that will test whether or not to process this item - need to filter out things like recommendations and lab values
    # values are free - they come with the procedure or test 
    
    if filterItem(item)
      return null unless item.code_list_id?

      if item.specific_occurrence?
        # Not sure this is right?  SHould this map the occurance id and not hte code list as it could be reused?
        if alreadySeen[item.code_list_id]?[item.specific_occurrence]?
          logger "  ALREADY SEEN: specific occurance #{item.specific_occurrence} #{item.description} #{item.code_list_id}"
          return null

        logger "  FIRST TIME SEEN: specific occurance #{item.specific_occurrence} #{item.description} #{item.code_list_id}"
        alreadySeen[item.code_list_id] ||= {}
        alreadySeen[item.code_list_id][item.specific_occurrence] = true

      if costs[item.code_list_id]
        costAvailabilityDetails[item.code_list_id] =
          title: item.title
          costs: costs[item.code_list_id]
        return costs[item.code_list_id]
      else
        logger "NO COST INFO: #{item.title} [#{item.code_list_id}]"
        costAvailabilityDetails[item.code_list_id] =
          title: item.title
        return null

    else
      return null

  # Caluculate the min and max values for a set of items and return the results

  calculateMinMax = (items, conjunction, count=null) ->
    subResults = (r for r in items when r) # Filter out nulls
    if subResults.length > 0
      if count 
        logger "have a count of #{count}"
        # For OR min is the min of all mins, and max is the max of all maxes
        # PWKFIX: consider if we want worst case (max of all maxes) or best case (min of all maxes)
        min = Math.min (r.min for r in subResults)...
        max = Math.max (r.max for r in subResults)...
        min: min * 2
        max: max * 2
      else  
        switch conjunction
          when 'or'
            logger "OR MIN: #{ (r.min for r in subResults)}  MAX: #{(r.max for r in subResults)}"
            # For OR min is the min of all mins, and max is the max of all maxes
            min: Math.min (r.min for r in subResults)...
            max: Math.max (r.max for r in subResults)...
          when 'and'
            logger "AND MIN: #{ (r.min for r in subResults)}  MAX: #{(r.max for r in subResults)}"
           
            # For AND min is the sum of all mins, and max is the sum of all maxes
            min: (r.min for r in subResults).reduce (x, y) -> x + y
            max: (r.max for r in subResults).reduce (x, y) -> x + y
          else
            logger "ERROR: unknown conjunction #{conjunction}"
            null
  
  handleTemporalReferences = (item) ->
    itemCosts = []
    if item.temporal_references? 
      logger "Temporal references #{item.title}"
      for tr in item.temporal_references
        logger "* Reference type: #{tr.type}"
        itemCosts.push(calculateRecursive(tr.reference)) 
      logger "FIN Temporal references #{item.title}"
    return itemCosts


  handleDerivations = (item) -> 
    logger "Derivation #{item.derivation_operator}"

    subResults = (calculateRecursive(i) for i in item.children_criteria)

    count = null
    if item.subset_operators? 
      result = (so for so in item.subset_operators when so.type is "COUNT")
      if result.length > 0
        count = result[0].value.low.value #total hack of a line comeback and do this right
        logger "Derivation count #{count}"
    conjunction = (item.derivation_operator == "UNION")? "or" : "and"
    min_max =  calculateMinMax(subResults, conjunction, count)
    logger "Finished Derivation #{item.derivation_operator}"
    return min_max

  handleConjunction = (item) ->
    logger "CONJ #{item.conjunction}"
    subResults = (calculateRecursive(i) for i in item.items)
    min_max =  calculateMinMax(subResults, item.conjunction)
    logger "FIN CONJ #{item.conjunction}"
    return min_max

  # Calculate the cost of a tree of items recursively
  calculateRecursive = (item) ->
    return null if !item || item.negated?
    try 
      indent+= 1
      # RD: need to pull and or logic out to separate method to allow it to be used by derivations without the need to recode 
      # basically the same logic elsewhere

      # RD: need to look for derivations and handel accordingly
      # if item.derivation?
      if item.conjunction?
        min_max =  handleConjunction(item)
        logger "min: #{min_max.min}   max: #{min_max.max}" if min_max
        return min_max
      else if item.type == "derived" 
        min_max =  handleDerivations(item)
        logger "min: #{min_max.min}   max: #{min_max.max}" if min_max
        return min_max
      else if item.code_list_id?
        itemCosts = [lookupSingle(item)]
        # PWKFIX: Can temporal references have conjunctions? no
        # PWKFIX: Assumes temporal references can contain items that don't appear elsewhere
        # For now simply sum the costs of all temporal references with the parent item
        Array::push.apply itemCosts,  handleTemporalReferences(item)
          #items.push(tr.reference) for tr in item.temporal_references when tr.reference.code_list_id
        # itemCosts = (lookupSingle(i) for i in items)

        itemCosts = (ic for ic in itemCosts when ic) # Prune out nulls
        if itemCosts.length > 0
          min_max =  itemCosts.reduce (x, y) ->
            min: x.min + y.min
            max: x.max + y.max
          logger "min: #{min_max.min}   max: #{min_max.max}" if min_max
          return min_max

      else
        if typeof(item) == 'string'
          logger "Unrecognized item: #{item}"
        else
          logger "Unrecognized item:"
          logger item
        null
    finally
      indent -= 1

  # Pre-populate the list of already seen codes with codes from the denominator and
  # population, which we shouldn't include in the cost calculation
  indent = 0
  logger "Population"
  logger calculateRecursive(@_doc.population)
  indent = 0
  logger  "DENOM"
  logger calculateRecursive(@_doc.denominator)
  indent = 0
  # PWKFIX Remove _doc when schema updates are checked in
  logger "Numer"
  min_max = calculateRecursive(@_doc.numerator)
  indent = 0
  return [min_max, costAvailabilityDetails]

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

# EXPLAINME are these supposed to be empty functions?
measureSchema.virtual('financial.high').get ->
measureSchema.virtual('financial.low').get ->
measureSchema.virtual('financial.average').get ->
measureSchema.virtual('financial.untreated_cost').get ->
  Math.floor(Math.random() * 500)
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
