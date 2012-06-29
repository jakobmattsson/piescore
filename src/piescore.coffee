exports.makeObject = ->
  obj = {}
  for i in [0..arguments.length/2]
    obj[arguments[i*2]] = arguments[i*2+1]
  obj

exports.argsToArray = -> 
  x for x in arguments

exports.block = (f) -> f()

exports.toKeyValues = (source) ->
  Object.keys(source).map (key) ->
    key: key
    value: source[key]

exports.attachEvent = (obj, eventName, callback) ->
  onEventName = "on" + eventName
  if obj.addEventListener
    obj.addEventListener(eventName, callback, false)
  else if obj.attachEvent
    obj.attachEvent(onEventName, callback)
  else
    currentEventHandler = obj[onEventName]
    obj[onEventName] = () ->
      if typeof currentEventHandler == 'function'
        currentEventHandler.apply(this, arguments)
      callback.apply(this, arguments)

exports.removeChildren = (element) ->
  argsToArray(element.children).forEach (x) ->
    element.removeChild(x)

exports.replaceChildren = (id, node) ->
  parent = window.document.getElementById id
  underline.removeChildren parent
  parent.appendChild node

