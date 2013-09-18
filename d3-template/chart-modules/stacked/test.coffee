# stacked area chart

require.config({
  baseUrl: ''
  map:
    '*':
      'css': '/javascript/libs/require-css/css'
      'text': '/javascript/libs/require-text'
})

require ['chart.js', '../common/d3-tooltip.js', '../utils/sum.js'], (chartMaker, tooltip, sum) ->

  $.get("data.js").done (raw) ->
    raw = JSON.parse raw


    chart = chartMaker()
    .key((g) -> g.method)
    .values((g) -> g.values)
    .x((d) -> d.day)
    .y((d) -> d.visits)
    .mouseover( (key) -> console.log 'over', key)
    .mouseout( (key) -> console.log 'out', key)
    .mousemove (date) -> #console.log date

    plot = (toDate) ->
      data = raw.filter (d) -> d[0].date < toDate.valueOf()

      groups = _(data.map((tuple)-> tuple[1].map((md) ->
        method:md.method
        date:tuple[0].date
        visits: sum(md.data.map (d) -> d.visits)
        subscribers: sum(md.data.map (d) -> d.subscribers)
      )))
      .chain().flatten().groupBy((d) -> d.method).value()



      # add missing data points
      dateRange = d3.extent data.map (d) ->new Date(d[0].date)


      msInaDay = 24*60*60*1000
      _.keys(groups).forEach (key) ->
        group = groups[key]
        index = -1
        for i in [+dateRange[0]..+dateRange[1]] by msInaDay
          ++index
          day = new Date(i)
          d = _(group).filter( (d) -> Math.abs(d.date - +day) < 1000)[0]

          if !d
            d = {method: key, date: day.valueOf(), visits: 0, subscribers: 0}
            group.splice index, 0, d

          d.day = day
          d.conv =if d.visits > 0 then d.subscribers/ d.visits else 0

          # add moving average values to each data point
          howMany = 6
          d.conv_cma = [-howMany..index].map((j) ->
            group[if j > -1 then j else 0].conv).reduce((a,b) ->a+b)/(index+howMany+1)
          d.conv_ma = [index-howMany..index].map((j) ->
            group[if j > -1 then j else 0].conv).reduce((a,b) ->a+b)/(howMany+1)
          groups[key] = group



      chartData = _(groups).map((arr,method) -> {method:method, values:arr, visits: sum arr.map (d) -> d.visits} )

      colors = d3.scale.category20()

      chartData = _(chartData).sortBy( (a) -> -a.visits).map((g,i) ->
        g.color = colors(i)
        g
      )


      #[{color,method,visits,values:[{day,visits}]}]
      console.log JSON.parse JSON.stringify chartData

      d3.select('#chart').datum(chartData).call chart
    #end plot



    plot new Date(2013,6,14)

    setTimeout ()->

      plot new Date(2013,6,9)

    , 2000




    #controls for visits chart
    $offsets = d3.select("body").selectAll('span.offset')
    .data([{n: 'Cumulative', v:'zero'},{n: 'Normalized', v:'expand'}]).enter().append('span').attr('class', 'offset')
    $offsets.append('input').attr('type','radio').attr('name', 'offset').attr('id', (d) -> 'offset-' + d.v)
    .attr('checked', (d) -> if 'zero' == d.v then 'checked' else null)
    .on('change', (val) ->
        chart.stackOffset val.v
        d3.select('#chart').call chart
      )
    $offsets.append('label').attr('for', (d) -> 'offset-' + d.v).text((d) -> d.n)
