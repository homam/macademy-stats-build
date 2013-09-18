require.config({
  baseUrl: ''
  map:
    '*':
      'css': '/javascript/libs/require-css/css'
      'text': '/javascript/libs/require-text'
})

require ['chart.js'], (chartMaker) ->
  testData = [
    {name: 'A long name', value: 645},
    {name: 'Some name', value:441},
    {name: 'Short', value: 273}
  ]

  chart = chartMaker().margin({right:120}).width(400)
  .colors(d3.scale.category20b())
  d3.select('#chart').datum(testData).call chart

  setTimeout ()->
    newData = testData.map((d)->{name:d.name,value:d.value*Math.random()}).map (d) -> [d.name, d.value]
    chart.width(300)
    chart.height(200)
    chart.names (d) -> d[0]
    chart.values (d) -> d[1]
    d3.select('#chart').datum(newData).call chart
  ,2000