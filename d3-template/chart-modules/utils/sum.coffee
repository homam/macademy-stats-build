define [], () ->
  sum = (arr) ->
    if(arr.length == 0)
      return 0
    if (arr.length == 1)
      return arr[0]
    return arr.reduce((a,b) ->a+b)