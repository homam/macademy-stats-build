require.config({
  baseUrl: ''
  map:
    '*':
      'css': '/libs/require-css/css'
      'text': '/libs/require-text'
})

DefaultExpirationMilliseconds = 1 * 3600 * 1000;
CurrentCacheItems = {};
GetCacheItem = (key) ->
        existing = CurrentCacheItems[key]
        if existing
            return existing;
        CurrentCacheItems[key] = new CacheItem(key, DefaultExpirationMilliseconds)
        return CurrentCacheItems[key]

class CacheItem
    constructor: (@key, @expirationMilliseconds) ->
    data: null #maybe also use this to indicate validity? if null then invalid?
    lastUpdate: 0 #the beginning of time
    setData: (newData) ->
        @lastUpdate = new Date()
        @data = newData
    isValid: ->  (new Date() - @lastUpdate) < @expirationMilliseconds
    invalidate: -> @lastUpdate = 0

class Chart
  constructor: (@api, @selector, @maker, @map) ->
    @chart = maker(@)
  update: (from, to, api = @api) =>
    api += "?from=#{from}&to=#{to}"
    self = @
    cacheItem = GetCacheItem(api)
    if(!cacheItem.isValid())
        d3.json api, (raw) ->
            cacheItem.setData(raw)
            d3.select(self.selector + " .chart").datum(self.map(raw)).call self.chart
    else
        #not assuming already draw! redundanct in our specific case
        d3.select(self.selector + " .chart").datum(self.map(cacheItem.data)).call self.chart

require ['../../chart-modules/bar/chart.js',
         '../../chart-modules/pie/chart.js',
         '../../chart-modules/common/d3-tooltip.js'],
(barChart, pieChart, tooltip) ->

  charts = []

  # Trial Chapter Used by
  charts.push new Chart(
    "http://stats.macademy.com/Home/TrialChapterVisits",
    "#UsersTrialChapterVisits",
    (->  pieChart().margin({right:0, left: 0, bottom: 40})
    .legendsPositoin("bottom")
    .width(300).height(300)
    .colors(d3.scale.category10())),
  (raw) ->
    d = raw[0]
    return [
      {name: 'Visited Trial Chapter', value: d['Visits']}
      {name: '', value: d['Users'] - d['Visits']}
    ]
  )

  # Buyers that Visited Trial Chapter before Purchase
  charts.push new Chart(
    "http://stats.macademy.com/Home/TrialChapterVisitsByBuyers",
    "#BuyersTrialChapterVisits",
    (->  pieChart().margin({right:0, left: 0, bottom: 40})
    .legendsPositoin("bottom")
    .width(300).height(300)
    .colors(d3.scale.category10())),
  (raw) ->
    d = raw[0]
    return [
      {name: 'Visited Trial Chapter', value: d['Visits']}
      {name: '', value: d['Users'] - d['Visits']}
    ]
  )

  # Funnel
  charts.push new Chart(
    "http://stats.macademy.com/Home/IapEventsPerUser",
    "#IapEventsPerUser",
    ((self)->
      barChart().width(700).height(300).devs(->0)
      .tooltip(tooltip().text((d) ->d3.format(',f') d.value))
      .margin({bottom: 95}).funnel(true).xAxis({labelsDy: "1em"})),
    (raw) ->
      data = _(raw[0]).map((value, key) -> {name: key, value: value})
      @total = data[0].value
      data
  )
  # IAP Requests before Purchase
  charts.push new Chart(
    "http://stats.macademy.com/Home/IapRequestsBeforePurchaseHistogram",
    "#IapRequestsBeforePurchaseHistogram",
    ((self)-> barChart().tooltip(tooltip().text((d) -> d3.format('.2p') d.value/self.total))
    .devs(->0)
    .margin({bottom: 45, left: 50}).width(465).height(200).drawExpectedValue(true).coalescing(10)
    .xAxis({text:"Page Visits", dy: "-.35em"})
    .yAxis({text:"Users", dy: ".75em"})
    )
    (raw) ->
      extent = d3.extent raw.map((d) -> d['Requests'])
      raw = [extent[0]..extent[1]].map (requests) ->
        (raw.filter (r) -> r['Requests'] == requests)[0] || {Requests: requests, Users: 0}
      data = _(raw).map((d) -> {name: d['Requests'], value: d['Users']})
      @total = data.map((d) -> d.value).reduce (a,b) -> a+b
      return data
  )


  # Purchase made a...
  charts.push new Chart(
    "http://stats.macademy.com/Home/ViewOfPurchase",
    "#ViewOfPurchase",
    (->  pieChart().margin({right:100, left: 0, bottom: 0})
    .legendsPositoin("right")
    .width(350).height(350)
    .colors(d3.scale.category10())),
    (raw) ->
      _(raw).map((d) -> {name: d['View'], value: d['Count']})
  )



  # Registered Users
  usersChart = new Chart(
    "http://stats.macademy.com/Home/AppUsersSources",
    "#AppUsersSources",
    (-> pieChart().margin({right:100, left: 0, bottom: 0})
    .legendsPositoin("right")
    .width(350).height(350)
    .colors((e) -> {'facebok':'#1f77b4', 'none':'gray', 'form':'green'}[e]))
    (raw) -> _(raw).map((d) -> {name: d['Source'] ? "none", value: d['Users']})
  )
  $("input[name=buyers]").on "change", ->
    updateChart usersChart, ( if "true" == $(this).val() then "http://stats.macademy.com/Home/AppUsersSourcesAtPurchase" else "http://stats.macademy.com/Home/AppUsersSources")

  charts.push usersChart

  # Usage before Purchase
  charts.push new Chart(
    "http://stats.macademy.com/Home/VisitsBeforePurchaseHistogram",
    "#VisitsBeforePurchaseHistogram",
    ((self)->barChart().width(465).height(200).devs(->0)
    .tooltip(tooltip().text((d) -> d3.format('.2p') d.value/self.total))
    .margin({bottom: 45, left: 50}).drawExpectedValue(true).coalescing(10)
    .xAxis({text:"Page Visits", dy: "-.35em"})
    .yAxis({text:"Users", dy: ".75em"})
    )
    (raw) ->
      extent = d3.extent raw.map((d) -> d['Visits'])
      raw = [extent[0]..extent[1]].map (visits) -> (raw.filter (r) -> r['Visits'] == visits)[0] || {Visits: visits, Users: 0}
      data = _(raw).map((d) -> {name: d['Visits'], value: d['Users']})
      @total = data.map((d) -> d.value).reduce (a,b) -> a+b
      return data
  )

  # Usage after purchase
  charts.push new Chart(
    "http://stats.macademy.com/Home/UsageAfterPurchase",
    "#UsageAfterPurchase",
    ((self)-> barChart().width(700).height(300).devs(->0)
    .tooltip(tooltip().text((d) -> d3.format('.2p') d.value/self.total))
    .margin({bottom: 45, left: 50}).drawExpectedValue(true).coalescing(20)
    .xAxis({text:"Page Visits", dy: "-.35em"})
    .yAxis({text:"Users", dy: ".75em"})
    ),
    (raw) ->
      extent = d3.extent raw.map((d) -> d['Visits'])
      raw = [extent[0]..extent[1]].map (visits) -> (raw.filter (r) -> r['Visits'] == visits)[0] || {Visits: visits, Users: 0}
      data = _(raw).map((d) -> {name: d['Visits'], value: d['Users']})
      @total = data.map((d) -> d.value).reduce (a,b) -> a+b
      return data
  )

  charts.push {
    api: "http://stats.macademy.com/Home/QuickStats"
    render: (stats) ->
      ['Visits', 'Users', 'Purchases'].forEach (i) ->
        $("#QuickStats [data-raw] [data-"+i+"]").text(d3.format(',f') stats[i])
        $("#QuickStats [data-ratio] [data-"+i+"]").text(d3.format('.2p') stats[i]/stats.Visits )
    update: (from, to) ->
      self = this
      api = this.api + "?from=#{from}&to=#{to}"
      cache = GetCacheItem api
      if cache.isValid()
        self.render cache.data
      else
        d3.json api, (stats) ->
          cache.setData stats[0]
          self.render stats[0]
  }

  #charts = [charts[1]]

  # updating

  ymdDate = d3.time.format("%Y-%m-%d")

  $("input[type=date]").attr("max", ymdDate(new Date(new Date().getTime() + 3600*1000*24*1)))

  $("#fromDate").val(ymdDate(new Date(new Date().getTime() - 3600*1000*24*1)))
  $("#toDate").val(ymdDate(new Date(new Date().getTime() + 3600*1000*24*1))).change()

  updateCharts = () ->
    charts.forEach (chart) -> updateChart(chart)
    

  updateChart = (chart, api = null) ->
    chart.update($("#fromDate").val(), $("#toDate").val(), api)

  $("input[type=date]").on 'change', ->
    updateCharts()

  updateCharts()

  #aux function, converts YMD string Date to Date object
  getDate = (stringYMDDate) ->
    fDateArray = stringYMDDate.split("-")
    fDate = new Date(fDateArray[0], fDateArray[1] - 1, fDateArray[2])

  #aux function, takes a date in Y-m-d format, and returns a Date object shifted by milliShift
  shiftDate = (stringYMDDate, milliShift)->
    fDate = getDate(stringYMDDate)
    new Date(fDate.getTime() + milliShift)

  #updates date ui by shifting their value by 'amount' milliseconds
  shiftDateUI = (amount) ->
    from = shiftDate($("#fromDate").val(), amount)
    to = shiftDate($("#toDate").val(), amount)
    $("#fromDate").val(ymdDate(from))
    $("#toDate").val(ymdDate(to)).change()
  
  shiftDatesMinus = -> shiftDateUI -3600*24*1000
  shiftDatesPlus = -> shiftDateUI 3600*24*1000

  setFrom = (from) ->
    $("#fromDate").val(ymdDate(from))
    $("#toDate").val(ymdDate(shiftDate($("#fromDate").val(), 24*3600*1000))).change()

  $("#todayDateMinus").click(shiftDatesMinus)
  $("#todayDatePlus").click(shiftDatesPlus)
  $("#todayDate").click(-> setFrom(new Date()))

  #range length = 1 day
  customDateRanges =
    '0':'2013-09-16'
    '1':'2013-09-14'
    '2':'2013-09-15'

  $(".windowsPhoneStyleBtns").each ->
    $(this).mouseover ->
        $(this).addClass 'hover'
    $(this).mouseout ->
        $(this).removeClass 'hover'

  $("input[id^=app]").each (i,e) ->
    $(e).click ->
        $("input[id^=app]").removeClass('active')
        setFrom getDate customDateRanges[i]
        $(this).addClass 'active'
