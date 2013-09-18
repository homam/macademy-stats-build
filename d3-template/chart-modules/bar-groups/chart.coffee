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


    x0 = d3.scale.ordinal().rangeRoundBands([0,width], .1)
    x1 = d3.scale.ordinal()
    y = d3.scale.linear().range([height,0])

    xAxis = d3.svg.axis().scale(x0).orient('bottom')
    yAxis = d3.svg.axis().scale(y).orient('left').tickFormat(d3.format(','))
    .tickSize(-width,0,0)


    mainNameMap = (d) ->d.name
    subNameMap = (d) ->d.name
    mainValueMap  = (d) ->d.value
    subValueMap = (d)->d.value
    subValueDevMap = (d) ->d.stdev

    color = d3.scale.category10()

    tooltip = () ->


    dispatch = d3.dispatch('mouseover', 'mouseout')



    # configurable properties

    properties = {
      width: new Property (value) ->
        width = value - margin.left-margin.right
        x0.rangeRoundBands([0,width], .1)
        yAxis.tickSize(-width,0,0)

      height: new Property (value) ->
        height = value - margin.top-margin.bottom
        y.range([height,0])

      margin: new Property (value) ->
        margin = value
        properties.width.reset()
        properties.height.reset()

      yAxisTickFormat: new Property (value) ->
        yAxis.tickFormat(value)

      mainNames : new Property (value) -> mainNameMap = value

      mainValues : new Property (value) ->mainValueMap = value

      subNames : new Property (value) -> subNameMap = value

      subValues : new Property (value) ->subValueMap = value

      subDevs : new Property (value) -> subValueDevMap = value

      tooltip : new Property (value) -> tooltip = value
    }

    properties.width.set(width)
    properties.height.set(height)

    chart = (selection) ->
      selection.each (data) ->

        $selection = d3.select(this)

        $svg = $selection.selectAll('svg').data([data])
        $gEnter = $svg.enter().append('svg').append('g')

        $svg.attr('width', width+margin.left+margin.right).attr('height', height+margin.top+margin.bottom)
        $g = $svg.select('g').attr('transform', "translate(" + margin.left + "," + margin.top + ")")


        $gEnter.append('g').attr('class', 'x axis')
        $xAxis = $svg.select('.x.axis').attr("transform", "translate(0," + (height)+ ")")

        $gEnter.append('g').attr('class', 'y axis')
        $yAxis = $svg.select('.y.axis')


        hierarchy = data

        allSubKeys = _.uniq _.flatten hierarchy.map((d) -> mainValueMap(d).map subNameMap)
        allMainKeys = _.flatten hierarchy.map mainNameMap


        x0.domain(allMainKeys)
        x1.domain(allSubKeys).rangeRoundBands([0, x0.rangeBand()])
        y.domain([0, d3.max _.flatten hierarchy.map (h) -> mainValueMap(h).map subValueMap])


        $main = $g.selectAll('.main').data(hierarchy)
        $main.enter().append('g').attr('class','main')
        $main.attr('transform', (d) -> "translate(" + x0(mainNameMap(d)) + ",0)")

        $rect = $main.selectAll('rect.conv').data(mainValueMap)
        $rect.enter().append('rect').attr('class', 'conv')
        .call(tooltip)
        $rect.transition().duration(200).attr('width', x1.rangeBand())
        .attr('x', (d,i) ->x1(subNameMap(d)))
        .attr('y', (d) -> y(subValueMap(d)))
        .attr('height', (d)-> height-y(subValueMap(d)))
        .style('fill', (d,i)-> color allSubKeys.indexOf(mainNameMap(d)))

        $rect.exit()#.transition().duration(200)
        .attr('y', (d) ->0)
        .attr('height', 0)#.attr('class', 'conv exit')

        # start standard deviation lines

        $devG = $main.selectAll('g.dev').data(mainValueMap)
        $devG.enter().append('g').attr('class', 'dev')
        $devG.transition().duration(200)
        .attr('transform', (d) -> 'translate(0,'+(-height+y(mainValueMap(d))-(-height+y(subValueDevMap(d)))/2)+')')

        $devUpperLine = $devG.selectAll('line.dev.up').data((d) -> [d])
        $devUpperLine.enter().append('line').attr('class', 'dev up')
        $devUpperLine.transition().duration(200)
        .attr('x1', _.compose(x1, subNameMap)).attr('x2', (d) -> _.compose(x1, subNameMap)(d)+x1.rangeBand())
        .attr('y1', _.compose y, subValueDevMap).attr('y2', _.compose y, subValueDevMap)

        $devLowerLine = $devG.selectAll('line.dev.low').data((d) -> [d])
        $devLowerLine.enter().append('line').attr('class', 'dev low')
        $devLowerLine.transition().duration(200)
        .attr('x1', _.compose(x1, subNameMap)).attr('x2', (d) -> _.compose(x1, subNameMap)(d)+x1.rangeBand())
        .attr('y1', (d) -> y(0)).attr('y2', (d) -> y(0))

        $devrect = $devG.selectAll('rect.dev').data((d) -> [d])
        $devrect.enter().append('rect').attr('class', 'dev')
        $devrect.transition().duration(200).attr('width', x1.rangeBand()*.25)
        .attr('x', (d) -> x1(subNameMap(d))+x1.rangeBand()*.375)
        .attr('y', _.compose y, subValueDevMap)
        .attr('height', (d)-> height- (_.compose y, subValueDevMap)(d))

        $devG.exit().select('rect').attr('height', 0).attr('y', () ->0).attr('width', 0)
        $devG.exit().selectAll('line').attr('y1', 0).attr('y2', 0)

        # end standard deviation lines



        $xAxis.transition().duration(200).call(xAxis)
        $yAxis.transition().duration(200).call(yAxis)

        $legend = $g.selectAll('.legend').data(allSubKeys)
        $legendEnter = $legend.enter().append('g').attr('class', 'legend')
        $legend.attr('transform', (d,i) -> "translate(0," + (i*20-margin.top) + ")")



        $legendEnter.append('rect')
        $legend.select('rect')
        .attr('x', width-18).attr('width', 18).attr('height', 18)
        .style('fill', (d) -> color allSubKeys.indexOf(d))
        $legendEnter.append('text')
        $legend.select('text')
        .attr('x', width-24).attr('y', 9).attr('dy', '.35em').style('text-anchor', 'end')
        .text((d) -> d)

        null # selection.each()
    null # chart()




    # expose the properties

    chart = Property.expose(chart, properties)
    chart.mouseover = (handler) -> dispatch.on('mouseover', handler)

    return chart