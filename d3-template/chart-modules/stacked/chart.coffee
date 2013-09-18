# stacked area chart
define ['../common/property'], (Property) ->
  () ->
    # configs
    margin =
      top: 20
      right: 40
      bottom: 20
      left: 50
    width = 720
    height = 300

    #yBMap = (d) -> d[1]

    x = d3.time.scale()
    y = d3.scale.linear()




    xAxis = d3.svg.axis().scale(x).orient('bottom').tickFormat(d3.time.format("%b %d"))
    yAxis = d3.svg.axis().scale(y).orient('left')



    # configurable properties

    properties = {
      width: new Property (value) ->
        width = value - margin.left-margin.right
        x.range([0,width])
        xAxis.scale(x)
        yAxis.tickSize(-width,0,0)

      height: new Property (value) ->
        height = value - margin.top-margin.bottom
        xAxis.tickSize(-height,0,0)
        y.range([height,0])

      margin: new Property (value) ->
        margin = _.extend margin, value # value might be missing some margins (like right, top ...)
        properties.width.reset() # width and height depend on margin
        properties.height.reset()

      x : new Property
      y : new Property
      values: new Property

      key :  new Property
      keyFilter : new Property
      stackOffset : new Property

      #todo: add colorMap to properties


      transitionDuration:  new Property

      tooltip : new Property
    }

    properties.width.set(width)
    properties.height.set(height)
    properties.stackOffset.set('zero')
    properties.transitionDuration.set(500)
    properties.keyFilter.set(() -> true)



    dispatch = d3.dispatch('mouseover', 'mouseout', 'mousemove')

    chart = (selection) ->
      selection.each (data) ->


        xMap = properties.x.get()
        yMap = properties.y.get()
        keyMap = properties.key.get()
        valuesMap = properties.values.get()
        keyFilter = properties.keyFilter.get()
        stackOffset = properties.stackOffset.get()
        transitionDuration = properties.transitionDuration.get()

        area = d3.svg.area().x((d) -> x(xMap(d))).y0((d) -> y(d.y0)).y1((d) -> y(d.y0 + d.y))


        stack = d3.layout.stack()
        .offset(stackOffset)
        .x(xMap).y(yMap)
        .order((sdata) ->
            m = sdata.map (d,i) -> {v: d.map((a) -> a[1]).reduce((a,b)->a+b), i:i}
            m = _(m).sortBy (d) -> d.v
            return _(m).map (d) -> d.i
          )
        .values(valuesMap)

        layers = stack(data)

        console.log layers

        keys = data.map(keyMap).filter(keyFilter)


        # set the y and y0 position of filtered out keys to 0, so keep the path for animation purpose but its area will be 0
        layers = layers.map (layer) ->
          if keys.indexOf(keyMap layer) < 0
            (valuesMap layer).map (d) ->
              d.y = d.y0 = 0
              d
          layer





        x.domain d3.extent valuesMap(layers[0]), xMap

        scaleLayers = stack(data.filter (d) -> keyFilter keyMap d)
        y.domain [0, d3.max(scaleLayers, (l) -> d3.max(valuesMap(l), (d) -> d.y0+d.y))]


        $selection = d3.select(this)

        $svg = $selection.selectAll('svg').data([data])
        $gEnter = $svg.enter().append('svg').append('g')

        $svg.attr('width', width+margin.left+margin.right).attr('height', height+margin.top+margin.bottom)
        $g = $svg.select('g').attr('transform', "translate(" + margin.left + "," + margin.top + ")")


        # how to use bisect, here mousemove is being fired on $layer

#        $gEnter.append("rect")
#        .attr("class", "overlay")
#        .attr("width", width)
#        .attr("height", height).style('opacity',0)
#        .on "mousemove", () ->
#            date = x.invert(d3.mouse(this)[0])
#            dispatch.mousemove(date)
#            #i = d3.bisector((d) -> d.date).left(data, date, 1)


        $layer = $g.selectAll('.layer').data(layers)
        $layer.enter().append('g').attr('class', 'layer')
        .on('mouseover', (d) -> dispatch.mouseover keyMap(d))
        .on('mouseout', (d) -> dispatch.mouseout keyMap(d) )
        .on "mousemove", () ->
            date = x.invert(d3.mouse(this)[0])
            dispatch.mousemove(date)
        $layer.attr('data-key', (d) -> keyMap d).style('fill', (d) ->d.color)
        .transition().duration(500).ease("sin-in-out").delay(200)
        .style('opacity', (d) -> if (keys.indexOf(keyMap(d))<0) then 0 else 1)

        $path = $layer.selectAll('path.area').data((d) -> [valuesMap(d)])
        $path.enter().append('path').attr('class', 'area')
        $path.style('fill', (d) -> d.color)
        $path.transition().duration(1000).ease("sin-in-out")
        .attr('d', area)



        # x axis
        $gEnter.append('g').attr('class', 'x axis')
        $xAxis = $svg.select('.x.axis').attr("transform", "translate(0," + (height)+ ")")
        $xAxis.transition().duration(transitionDuration).call(xAxis)
        .selectAll("text")
        .style("text-anchor", "end")
        .attr("dx", "-.8em")
        .attr("dy", ".15em")
        .attr("transform","rotate(-90)")

        # y line axis
        $gEnter.append('g').attr('class', 'y axis')
        $yAxis = $svg.select('.y.axis')
        $yAxis.transition().duration(transitionDuration).call(yAxis)









        null # selection.each()
    null # chart()




    # expose the properties

    chart = Property.expose(chart, properties)
    chart.mouseover = (delegate) -> dispatch.on('mouseover', delegate); return chart;
    chart.mouseout = (delegate) -> dispatch.on('mouseout', delegate); return chart;
    chart.mousemove = (delegate) -> dispatch.on('mousemove', delegate); return chart;

    return chart