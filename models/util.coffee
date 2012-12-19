module.exports = (mongoose, db) ->
  utilSchema = new mongoose.Schema
    _id: String
  @model = db.model 'system.js', utilSchema
  return this






