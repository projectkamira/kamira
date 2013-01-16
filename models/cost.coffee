mongoose = require 'mongoose'

# PWKFIX Eventually probably want to support data from multiple sources
CostSchema = new mongoose.Schema
  oid: String
  count: Number
  firstQuartile: Number
  thirdQuartile: Number
  mean: Number
  median: Number
  standardDev: Number

module.exports = mongoose.model 'Cost', CostSchema
