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
