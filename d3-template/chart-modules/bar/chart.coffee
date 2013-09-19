# bar
# some properties are specific for histograms
define ['../common/property'], (Property) ->
  () ->
    # configs
    margin =
      top: 20
      right: 0
      bottom: 20
      left: 70
    width = 720
    height = 300


    x = d3.scale.ordinal()
    y = d3.scale.linear()

    xAxis = d3.svg.axis().scale(x).orient('bottom')
    yAxis = d3.svg.axis().scale(y).orient('left').tickFormat(d3.format(','))


    formatPercent = d3.format('.2p')

    nameMap = (d) ->d.name
    valueMap  = (d) ->d.value
    devMap = null # (d) ->d.dev

    tooltip = () ->


    dispatch = d3.dispatch('mouseover', 'mouseout')



    # configurable properties

    properties = {
      width: new Property (value) ->
        width = value - margin.left-margin.right
        x.rangeRoundBands([0,width], .1)
        yAxis.tickSize(-width,0,0)

      height: new Property (value) ->
        height = value - margin.top-margin.bottom
        y.range([height,0])

      margin: new Property (value) ->
        margin = _.extend margin, value
        properties.width.reset()
        properties.height.reset()

      names : new Property (value) -> nameMap = value

      values : new Property (value) ->valueMap = value

      devs : new Property (value) -> devMap = value

      tooltip : new Property (value) -> tooltip = value

      funnel : new Property

      # numebr, used in histograms
      drawExpectedValue: new Property

      # number, used in histograms
      coalescing: new Property

      # {text, dy, labelsDy}
      xAxis: new Property

      # {text, dy, labelsDy}
      yAxis: new Property

    }


    properties.xAxis.set({labelsDy: ".75em"})
    properties.width.set(width)
    properties.height.set(height)

    chart = (selection) ->
      selection.each (data) ->

        $selection = d3.select(this)

        chartData = data

        # in histograms
        coalescing = properties.coalescing.get()

        statistics = null
        if !!coalescing or properties.drawExpectedValue.get()

          total = _(data).map((d) -> d.value).reduce (a,b) -> a+b
          distribution = _(data).map((d) -> d.name * (d.value/total))
          expectedValue = distribution.reduce (a,b) -> a+b
          variance = data.map((d) -> Math.pow((d.name-expectedValue),2)*(d.value/total)).reduce((a,b)->a+b)
          stnDev = Math.sqrt variance

          statistics = {
            expectedValue: expectedValue
            stnDev: stnDev
          }


        if !!coalescing
          if coalescing < (expectedValue + stnDev)
            coalescing = Math.ceil expectedValue + stnDev
          chartData = _(data).foldl ((acc, a) ->
            if a.name <= coalescing
              acc.push({name: a.name, value: a.value})
            else
              acc[acc.length-1].value += a.value
            return acc), []



        $svg = $selection.selectAll('svg').data([chartData])
        $gEnter = $svg.enter().append('svg').append('g')

        $svg.attr('width', width+margin.left+margin.right).attr('height', height+margin.top+margin.bottom)
        $g = $svg.select('g').attr('transform', "translate(" + margin.left + "," + margin.top + ")")


        $gEnter.append('g').attr('class', 'x axis')
        $xAxis = $svg.select('.x.axis').attr("transform", "translate(0," + (height)+ ")")

        $gEnter.append('g').attr('class', 'y axis')
        $yAxis = $svg.select('.y.axis')



        keys = _.flatten chartData.map nameMap
        x.domain(keys)
        y.domain([0, d3.max chartData.map valueMap ])

        $main = $g.selectAll('g.main').data(chartData)
        $mainEnter = $main.enter().append('g').attr('class','main')
        $main.transition().duration(200)

        $mainEnter.append('rect')
        .on('mouseover', (d) -> dispatch.mouseover(d))
        .on('mouseout', (d) -> dispatch.mouseout(d))
        .call(tooltip)

        $rect = $main.select('rect')
        $rect.transition().duration(200).attr('width', x.rangeBand())
        .attr('class', nameMap)
        .attr('x', (d) -> x(nameMap(d)))
        .attr('y', (d) -> y(valueMap(d)))
        .attr('height', (d)-> height-y(valueMap(d)))
        .style('fill', (d,i)-> '#ff7f0e')


        # in funnels
        if !!properties.funnel.get()
          total = data.map(valueMap)[0]
          $mainEnter.append('text').attr('class','percentage')
          $main.select('text.percentage')
          .attr('x', (d) -> x(nameMap(d)) + x.rangeBand()/2)
          #.attr('y', height-(height*.10))
          .attr('y', height+margin.bottom-10)
          .text((d,i) -> if i > 0 then (formatPercent valueMap(d) / total) else "of Total")
          .style("text-anchor", "middle")
          $mainEnter.append('text').attr('class','percentage-step')
          $main.select('text.percentage-step')
          .attr('x', (d) -> x(nameMap(d)) + x.rangeBand()/2)
          #.attr('y', height-(height*.25))
          .attr('y', height+margin.bottom-40)
          .text((d,i) -> if i >0 then (formatPercent valueMap(d) / valueMap(data[i-1])) else "of Last Step")
          .style("text-anchor", "middle")


        # in histograms
        if properties.drawExpectedValue.get()
          expectedValue = statistics.expectedValue
          stnDev = statistics.stnDev

          $expGEnter = $gEnter.append('g').attr('class','exp')
          $expG = $g.select('g.exp')
          .transition().duration(200)


          realX = (value) ->
            #debugger
            min = _.min(data.map (d) -> d.name)
            if value < min
              x(min)       #todo: what to do win value < min, the stnDev line will be at the left of the chart
              # x(min) - x(-1 * Math.floor value+min) - (value + Math.floor(value+min)) * x.rangeBand()
            else
              x(Math.floor value) + (value - Math.floor(value)) * x.rangeBand()

          addVerticalLine = (value, className) ->
            lineX = realX value
            $expGEnter.append('line').attr('class', className)
            $expG.select('line.' + className).transition().duration(200)
            .attr('x1', lineX).attr('x2', lineX)
            .attr('y1', 0).attr('y2', height)

          addHorizontalLine = (value, x1, x2, className) ->
            lineY = y value
            $expGEnter.append('line').attr('class', className)
            $expG.select('line.' + className).transition().duration(200)
            .attr('x1', realX x1).attr('x2', realX x2)
            .attr('y1', lineY).attr('y2', lineY)
            .style("stroke", "black")



          addVerticalLine expectedValue, "exp"
          addVerticalLine (expectedValue - stnDev), "leftStnDev"
          addVerticalLine (expectedValue + stnDev), "rightStnDev"

          #debugger
          console.log expectedValue,(expectedValue - stnDev), (expectedValue + stnDev)
          console.log realX(expectedValue),realX(expectedValue - stnDev), realX(expectedValue + stnDev)
          console.log coalescing
          console.log "----"

          do ->
            total = chartData.map((d) ->d.name).reduce (a,b) -> a+b
            distribution = _(data).map((d) -> d.value * (d.name/total))
            nameExpectedValue = distribution.reduce (a,b) -> a+b
            nameVariance = data.map((d) -> Math.pow((d.name-expectedValue),2)*(d.value/total)).reduce((a,b)->a+b)
            nameStnDev = Math.sqrt variance

            addHorizontalLine nameExpectedValue, (expectedValue - stnDev), (expectedValue + stnDev), "stnDev-hline"


        # deviation lines
        if !!devMap
          $devGEnter = $mainEnter.append('g').attr('class','dev')
          $devG = $main.select('g.dev')
          .transition().duration(200)
          .attr('transform', (d) -> 'translate(0,'+(-height+y(valueMap(d))-(-height+y(devMap(d)))/2)+')')

          $devGEnter.append('line').attr('class', 'dev up')
          $devG.select('line.dev.up')
          .transition().duration(200)
          .attr('x1', _.compose(x, nameMap)).attr('x2', (d) -> _.compose(x, nameMap)(d)+x.rangeBand())
          .attr('y1', _.compose y, devMap).attr('y2', _.compose y, devMap)

          $devGEnter.append('line').attr('class', 'dev low')
          $devG.select('line.dev.low')
          .transition().duration(200)
          .attr('x1', _.compose(x, nameMap)).attr('x2', (d) -> _.compose(x, nameMap)(d)+x.rangeBand())
          .attr('y1', y(0)).attr('y2',y(0))

          $devGEnter.append('rect').attr('class', 'dev')
          $devG.select('rect.dev')
          .transition().duration(200).attr('width', x.rangeBand()*.25)
          .attr('x', (d) -> x(nameMap(d))+x.rangeBand()*.375)
          .attr('y', _.compose y, devMap)
          .attr('height', (d)-> height- (_.compose y, devMap)(d))



        $main.exit().select('rect').attr('y', 0).attr('height', 0)




        xAxisProps = properties.xAxis.get()

        $xAxis.transition().duration(200).call(xAxis)
        .selectAll("text")
        .text((d) -> if !!coalescing and d >= coalescing then (d + "+") else d)
        .attr("dy", xAxisProps.labelsDy || ".75em")
        #.style("text-anchor", "end").style("font-size", "10px").attr("dx", "2em").attr("transform", "rotate(0)")
        $yAxis.transition().duration(200).call(yAxis)

        #xAxis label
        if !!xAxisProps
          $gEnter.append("text").attr("class", "x label")
          $g.select('text.x.label').attr("text-anchor", "end")
          .attr("x", width)
          .attr("y", height + margin.bottom )
          .text(xAxisProps.text).attr("dy",(xAxisProps.dy || 0));

        #yAxis label
        yAxisProps = properties.yAxis.get()
        if !!yAxisProps
          $gEnter.append("text").attr("class", "y label")
          $g.select('text.y.label').attr("text-anchor", "end")
          #.attr("x", 0 - margin.left)
          .attr("y", 0 - margin.left)
          .attr("dy", yAxisProps.dy || 0)
          .attr("transform", "rotate(-90)")
          .text(yAxisProps.text);

        null # selection.each()
    null # chart()




    # expose the properties

    chart = Property.expose(chart, properties)
    #chart.mouseover = (handler) -> dispatch.on('mouseover', handler)

    return chart