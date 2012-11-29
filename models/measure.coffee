module.exports = (mongoose, db) ->
  measureSchema = new mongoose.Schema {id:String, name:String}
    id: String
    name: String
    complexity:
      numerator:    Number
      denominator:  Number
      population:   Number
      exclusions:   Number
      exceptions:   Number
  @model = db.model 'measures', measureSchema
  return this