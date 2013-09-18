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

      transitionDuration:  new Property

      tooltip : new Property
    }

    properties.width.set(width)
    properties.height.set(height)
    properties.transitionDuration.set(500)
    properties.keyFilter.set(() -> true)



    dispatch = d3.dispatch('mouseover', 'mouseout', 'mousemove')

    chart = (selection) ->
      selection.each (raw) ->


        xMap = properties.x.get()
        yMap = properties.y.get()
        keyMap = properties.key.get()
        valuesMap = properties.values.get()
        keyFilter = properties.keyFilter.get()
        transitionDuration = properties.transitionDuration.get()


        data = raw.map (g) ->
          key: keyMap g
          color: g.color #todo use colorMap
          values: (valuesMap g).map (d) -> [xMap(d), yMap(d)]

        keys = data.map((g) -> g.key).filter(keyFilter)

        line = d3.svg.line().interpolate('basis')
        .x((d) -> x d[0]).y((d) -> y d[1])

        layers = data

        # set the y and y0 position of filtered out keys to 0, so keep the path for animation purpose but its area will be 0
        layers = layers.map (layer) ->
          if keys.indexOf(layer.key) < 0
            layer.values.map (d) ->
              d[1] = 0
              d
          layer





        x.domain d3.extent layers[0].values.map((d) -> d[0])

        scaleLayers = (data.filter (g) -> keys.indexOf(g.key) >-1)
        y.domain [0, d3.max(scaleLayers, (g) -> d3.max(g.values, (d) -> d[1]))]


        $selection = d3.select(this)

        $svg = $selection.selectAll('svg').data([data])
        $gEnter = $svg.enter().append('svg').append('g')

        $svg.attr('width', width+margin.left+margin.right).attr('height', height+margin.top+margin.bottom)
        $g = $svg.select('g').attr('transform', "translate(" + margin.left + "," + margin.top + ")")



        $line = $g.selectAll('.data.line').data(layers)
        $line.enter().append('path').attr('class', 'data line')
        $line.attr('data-key', (d) -> d.key).style('stroke', (d) ->d.color)
        .on('mouseover', (d) -> mouseEvents.mouseover d.key )
        .on('mouseout', (d) -> mouseEvents.mouseout d.key )
        $line.transition().duration(500).attr('d', (d) -> line(d.values))
        .style('opacity', (d) ->
            if (keys.indexOf(d.key)<0) then 0 else 1
          )


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