mongoose = require 'mongoose'

# PWKFIX Eventually probably want to support data from multiple sources
CostSchema = new mongoose.Schema
  oid: String
  count: Number
  min: Number
  firstQuartile: Number
  median: Number
  thirdQuartile: Number
  max: Number
  mean: Number
  standardDev: Number

module.exports = mongoose.model 'Cost', CostSchema
