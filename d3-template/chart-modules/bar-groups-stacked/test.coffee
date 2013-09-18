require.config({
  baseUrl: ''
  map:
    '*':
      'css': '/javascript/libs/require-css/css'
      'text': '/javascript/libs/require-text'
})

require ['chart.js', '../common/d3-tooltip.js'], (chartMaker, tooltip) ->
  testData = [
    {name: 'A', values: [{name: 'Alpha', value: 345, dev: 31}, {name: 'Beta', value: 45, dev: 11}]},
    {name: 'B', values: [{name: 'Alpha', value: 441, dev: 42}, {name: 'Beta', value: 400, dev: 6}]},
    {name: 'C', values: [{name: 'Alpha', value: 273, dev: 12}, {name: 'Beta', value: 89, dev: 30}]}
  ]

  chart = chartMaker().tooltip(tooltip().text((d) -> JSON.stringify(d)))
  d3.select('#chart').datum(testData).call chart


  return
  setTimeout ()->
    newData = testData.map((d)->
      {name:d.name,value:[d.value[0]]})
    chart.width(600)
    chart.height(200)
    chart.margin({top:0,left:30,bottom:20,right:0})
    #chart.names (d) -> d[0]
    #chart.values (d) -> d[1]
    #chart.devs (d) -> d[2]*0
    #chart.tooltip().text((d) -> d[0])
    d3.select('#chart').datum(newData).call chart

    setTimeout () ->
      d3.select('#chart').datum(testData).call chart
    , 10000
  ,2000