// Generated by CoffeeScript 1.6.3
(function() {
  var app, express, http, path;

  express = require('express');

  path = require('path');

  http = require('http');

  app = express();

  app.set('port', process.env.PORT || 3100);

  app.set('views', __dirname + '/views');

  app.set('view engine', 'ejs');

  app.use(express.logger('dev'));

  app.use(express.bodyParser());

  app.use(express.methodOverride());

  app.use(app.router);

  app.use(express.favicon());

  app.use('/chart-modules', express["static"]('d3-template/chart-modules'));

  app.use('/libs', express["static"]('d3-template/libs'));

  app.use('/reports', express["static"]('reports'));

  require('./routes').register(app);

  http.createServer(app).listen(app.get('port'), function() {
    return console.log("express started at port " + app.get('port'));
  });

}).call(this);

/*
//@ sourceMappingURL=app.map
*/
