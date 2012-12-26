exports.dashboard = (req, res) ->
  res.render 'dashboard',
    title: 'Dashboard'
    measures: req.measures

exports.complexity = (req, res) ->
  res.render 'complexity',
    title: 'Complexity'
    measures: req.measures

exports.financial = (req, res) ->
  res.render 'financial',
    title: 'Financial Data'
    measures: req.measures

exports.help = (req, res) ->
  res.render 'help',
    title: 'Help'
    measures: req.measures

exports.about = (req, res) ->
  res.render 'about',
    title: 'About'
    measures: req.measures
