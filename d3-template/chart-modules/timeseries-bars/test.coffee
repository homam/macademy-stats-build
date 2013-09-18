require.config({
  baseUrl: ''
  map:
    '*':
      'css': '/javascript/libs/require-css/css'
      'text': '/javascript/libs/require-text'
})

require ['chart.js', '../common/d3-tooltip.js'], (chartMaker, tooltip) ->

  d3.csv '/charts/simple/data/iraq-android-refs.json', (data) ->
    # parse data
    parseDate = d3.time.format("%m/%d/%Y").parse;
    data = data.map (d) ->
      d.date = parseDate(d.date)
      d.visits = +d.visits
      d.subs = +d.subs
      d.conv = +d.conv
      d


    groups = _(data).groupBy (d) -> d.ref
#    refs = _.chain(groups).keys().map (ref) ->
#      ref: ref
#      visits: groups[ref].map((d) -> d.visits).reduce (a,b) -> a+b
#    .sortBy((r) -> -r.visits).value()

    # add missing data points
    dateRange = d3.extent data.map (d) ->d.date
    msInaDay = 24*60*60*1000
    _.keys(groups).forEach (key) ->
      group = groups[key]
      index = -1
      for i in [+dateRange[0]..+dateRange[1]] by msInaDay
        ++index
        date = new Date(i)
        if !_(group).some( (d) -> Math.abs(+d.date - +date) < 1000)
          group.splice index, 0, {date: date, visits: 0, subs: 0, conv: 0}
          groups[key] = group




    chart = chartMaker()
    .width(800).margin({right:60,left:70,bottom:50})
    .tooltip(tooltip().text((d) -> JSON.stringify(d)))
    .x((d) -> d.date).y((d) -> d.visits).yB((d) -> d.subs)
    chart.mouseover (d) ->
      if(!!d)
        document.getElementById("mouse-val").innerHTML = d.date+':'+ d.visits
    d3.select('#chart').datum(groups['wap p11'].filter((d,i) -> i<15)).call chart




    setTimeout ()->
      chart.yDomain(d3.extent)
      d3.select('#chart').datum(groups['wap p155'].filter((d,i) -> i<5)).call chart
    , 2000
