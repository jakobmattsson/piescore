exports.makeObject = ->
  obj = {}
  for i in [0..arguments.length/2]
    obj[arguments[i*2]] = arguments[i*2+1]
  obj

exports.argsToArray = (args) ->
  x for x in args

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
  exports.argsToArray(element.children).forEach (x) ->
    element.removeChild(x)

exports.replaceChildren = (id, node) ->
  parent = window.document.getElementById id
  exports.removeChildren parent
  parent.appendChild node

exports.prepend = (target, e) ->
  if Array.isArray(target)
    [e].concat(target)
  else if typeof target == 'string'
    e + target
  else
    throw 'Must be string or array'

exports.append = (target, e) ->
  if Array.isArray(target)
    target.concat([e])
  else if typeof target == 'string'
    target + e
  else
    throw 'Must be string or array'

exports.contains = (target, e) -> target.indexOf(e) != -1

exports.toMap = (array, keySelector, valueSelector) ->
  if typeof keySelector == 'string'
    keySelectorString = keySelector
    keySelector = (e) -> e[keySelectorString]

  if typeof valueSelector == 'string'
    valueSelectorString = valueSelector
    valueSelector = (e) -> e[valueSelectorString]

  if !valueSelector?
    valueSelector = (e) -> e

  result = {}
  array.forEach (e) ->
    result[keySelector(e)] = valueSelector(e)

  result

exports.mapObjectAsync = (obj, f, callback) ->
  kvs = π.toKeyValues(obj)
  async.map kvs.pluck('value'), f, (err, data) ->
    if err
      callback(err)
      return
    zipped = _.zip(kvs, data)
    result = exports.toMap(zipped, ((x) -> x[0].key), '1')
    callback null, result

