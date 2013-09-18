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

    #yB = d3.scale.linear()
    #xB = d3.scale.ordinal()



    xAxis = d3.svg.axis().scale(x).orient('bottom')
    yAxis = d3.svg.axis().scale(y).orient('left')

    #yBAxis = d3.svg.axis().scale(yB).orient('right')


    # configurable properties

    properties = {
      width: new Property (value) ->
        width = value - margin.left-margin.right
        yAxis.tickSize(-width,0,0)
        x.range([0,width])
        #xB.rangeRoundBands([0,width],.2)

      height: new Property (value) ->
        height = value - margin.top-margin.bottom
        xAxis.tickSize(-height,0,0)
        y.range([height,0])
        #yB.range([height, 0])

      margin: new Property (value) ->
        margin = _.extend margin, value # value might be missing some margins (like right, top ...)
        properties.width.reset() # width and height depend on margin
        properties.height.reset()

      x : new Property
      y : new Property
      yDomain : new Property
      transitionDuration:  new Property

      tooltip : new Property
    }

    properties.width.set(width)
    properties.height.set(height)
    properties.yDomain.set (ys) -> [0, d3.max ys]
    properties.transitionDuration.set(500)



    #dispatch = d3.dispatch('mouseover', 'mouseout')

    chart = (selection) ->
      selection.each (data) ->

        xMap = properties.x.get()
        yMap = properties.y.get()

        x.domain(d3.extent data.map xMap)
        y.domain(properties.yDomain.get() data.map yMap)

        $selection = d3.select(this)

        $svg = $selection.selectAll('svg').data([data])
        $gEnter = $svg.enter().append('svg').append('g')

        $svg.attr('width', width+margin.left+margin.right).attr('height', height+margin.top+margin.bottom)
        $g = $svg.select('g').attr('transform', "translate(" + margin.left + "," + margin.top + ")")


        $gEnter.append('g').attr('class', 'x axis')
        $xAxis = $svg.select('.x.axis').attr("transform", "translate(0," + (height)+ ")")

        $gEnter.append('g').attr('class', 'y axis')
        $yAxis = $svg.select('.y.axis')


        transitionDuration = properties.transitionDuration.get()

        line = d3.svg.line().interpolate('basis').x(_.compose(x, xMap)).y(_.compose(y, yMap))
        $g.selectAll('path.line').data([data]).enter().append('path').attr('class', 'line')
        $g.selectAll('path.line').transition().duration(transitionDuration).ease("sin-in-out").attr('d', line)

        $xAxis.transition().duration(transitionDuration).call(xAxis)
        $yAxis.transition().duration(transitionDuration).call(yAxis)

        null # selection.each()
    null # chart()




    # expose the properties

    chart = Property.expose(chart, properties)
    #chart.mouseover = (handler) -> dispatch.on('mouseover', handler)

    return chart