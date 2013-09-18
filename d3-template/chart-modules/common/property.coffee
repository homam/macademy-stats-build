define [], () ->
  class Property
    constructor: (@_onSet) ->
      _value: null
    set: (value)->
      this._value = value
      if !!this._onSet
        this._onSet(value)
    get: () ->
      this._value
    reset: () ->
      this.set(this._value)

    # static
    Property.expose = (chart, properties) ->
      d3.keys(properties).forEach (k) ->
        p = properties[k]
        chart[k] = (val) ->
          if(!!arguments.length)
            p.set(val)
            chart
          else
            p.get()
      chart
