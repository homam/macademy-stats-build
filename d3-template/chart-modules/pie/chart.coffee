#pie
define ['../common/property'], (Property) ->
  () ->
    # configs
    margin =
      right: 50

    width = 300
    height = 300
    radius = Math.min(width,height)/2

    nameMap = (d) ->d.name
    valueMap  = (d) ->d.value

    legend = true

    #color = d3.scale.category10()

    formatNumber = d3.format(',f')
    formatPercent = d3.format('.1p')

    arc = d3.svg.arc()
    .outerRadius(radius).innerRadius(0);

    pie = d3.layout.pie().sort(null).value(valueMap);



    # configurable properties

    properties = {
      width: new Property (value) ->
        width = value - margin.right
        radius = Math.min(width,height)/2
        arc.outerRadius(radius)

      height: new Property (value) ->
        height = value
        radius = Math.min(width,height)/2
        arc.outerRadius(radius)

      margin : new Property (value) ->
        margin = value
        properties.width.reset()
        properties.height.reset()

      names : new Property (value) -> nameMap = value

      colors : new Property

      values : new Property (value) ->
        valueMap = value
        pie.value(value);

    }

    properties.width.set(width)
    properties.height.set(height)

    chart = (selection) ->
      selection.each (data) ->

        color = properties.colors.get() || d3.scale.category10()

        $selection = d3.select(this)

        $svg = $selection.selectAll('svg').data([data])
        $gEnter = $svg.enter().append('svg').append('g')

        $svg.attr('width', width+margin.right).attr('height', height)
        $g = $svg.select('g').attr('transform', "translate(" + width / 2 + "," + height / 2 + ")")

        $arc = $g.selectAll(".arc").data(pie(data))
        $arcEnter = $arc.enter().append("g")
        $arc.attr("class", (d) ->
          "arc " + nameMap(d.data));

        $arcEnter.append("path")
        $arc.select('path').transition().duration(500).attr("d", arc)
        $arc.select('path').style("fill", (d) -> color(nameMap(d.data)));


        total = $arc.data().map((d) -> valueMap(d)).reduce (a,b) -> a+b
        $arcEnter.append("text")
        $arc.select('text').attr("transform", (d) -> "translate(" + arc.centroid(d) + ")")
        .attr("dy", ".35em")
        .style("text-anchor", "middle")
        .text((d) -> formatNumber(valueMap(d.data)) + " (" +
          formatPercent(valueMap(d) /  total) + ")");

        if legend
          $gEnter.append('g').attr('class','legend')
          $legend = $g.select('.legend')
          .attr("transform", "translate("+(width/2)+"," + (-height/2) + ")")
          .attr("class", "legend")
          .attr("width", radius * 2)
          .attr("height", radius * 2)
          .selectAll("g")
          .data(data.map nameMap)
          .enter().append("g")
          .attr("transform", (d, i) -> "translate(0," + i * 20 + ")")

          $legend.append("rect")
          .attr("width", 18)
          .attr("height", 18)
          .style("fill", color);

          $legend.append("text")
          .attr("x", 24)
          .attr("y", 9)
          .attr("dy", ".35em")
          .text((d) -> d);





        null # selection.each()
    null # chart()




    # expose the properties

    chart = Property.expose(chart, properties)

    return chart