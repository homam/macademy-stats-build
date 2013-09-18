exports.register = (app) ->
  app.get '/', (req, res) ->
    res.render '../reports/dashboard/index', {}
  