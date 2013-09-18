define [], () ->
  # condition: (d) ->d.visits <= 100
  reduceLongTail = (condition, reducer, arr) ->
    if (arr.length<2)
      return arr
    tail = arr.filter(condition)
    if(tail.length < 2)
      return arr

    head = arr.filter (d) ->!condition d
    head.push reducer tail

    head