mongoose = require 'mongoose'

ConceptSchema = new mongoose.Schema
  code: String
  code_system_name: String
  display_name: String


valueSetSchemaDefinition =
  oid: String
  display_name: String
  concepts: [ConceptSchema]

ValueSetSchema = new mongoose.Schema valueSetSchemaDefinition, collection: 'health_data_standards_svs_value_sets'

module.exports = mongoose.model 'ValueSet', ValueSetSchema
