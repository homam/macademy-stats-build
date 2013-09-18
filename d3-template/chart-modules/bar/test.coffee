require.config({
  baseUrl: ''
  map:
    '*':
      'css': '/javascript/libs/require-css/css'
      'text': '/javascript/libs/require-text'
})

require ['chart.js', '../common/d3-tooltip.js'], (chartMaker, tooltip) ->
  testData = [
    {name:'A', value: 345, dev: 31},
    {name: 'B', value:441, dev: 42},
    {name: 'C', value: 273, dev: 12}
  ]

  chart = chartMaker().devs((d)->d.dev).tooltip(tooltip().text((d) -> JSON.stringify(d)))
  d3.select('#chart').datum(testData).call chart


  setTimeout ()->
    newData = testData.map((d)->{name:d.name,value:d.value*Math.random(),dev:d.dev}).map (d) -> [d.name, d.value, d.dev]
    chart.width(300)
    chart.height(200)
    chart.margin({top:0,left:30,bottom:20,right:0})
    chart.names (d) -> d[0]
    chart.values (d) -> d[1]
    chart.devs (d) -> d[2]*0
    chart.tooltip().text((d) -> d[0])
    d3.select('#chart').datum(newData).call chart
  ,2000