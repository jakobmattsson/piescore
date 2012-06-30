async = require 'async'
_s = require 'underscore.string'

exports.submodules = {}

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
  kvs = exports.toKeyValues(obj)
  async.map exports.pluck(kvs, 'value'), f, (err, data) ->
    if err
      callback(err)
      return
    zipped = _.zip(kvs, data)
    result = exports.toMap(zipped, ((x) -> x[0].key), '1')
    callback null, result


exports.submodules.serenade = (ser) ->
  serenadeModel: (data) ->
    model = ser({})
    Object.keys(data).forEach (key) ->
      if Array.isArray(data[key])
        model.set(key, new ser.Collection(data[key]))
      else
        model.set(key, data[key])
    model




# Assumes:
# * viaduct-server with /viduact.html in the root
# * rester-service (metabody:true)
#
# Uses the following parameters:
# * url, qs, origin, data, type, username, password
exports.submodules.viaduct = (viaduct) ->
  request: (params, callback) ->

    url = params.url
    qs = _.extend({}, params.qs, { metabody: true })

    if params.origin && !_s.startsWith(params.url, 'http://') && !_s.startsWith(params.url, 'https://')
      url = params.origin + params.url

    viaduct.host(exports.parseOrigin(url) + '/viaduct.html')


    # Add on the querystring
    querystring = Object.keys(qs).map((key) -> key + "=" + qs[key]).join("&")
    if _s.contains(url, '?')
      querystring = "&" + querystring
    else
      querystring = "?" + querystring
    url += querystring

    # Perform the request
    viaduct.request
      json: params.data || {}
      method: params.type || 'GET'
      auth:
        username: params.username
        password: params.password
      url: url
    , (err, response, body) ->
      if err || response.statusCode != 200
        callback({ msg: 'Transport failed' })
      else if body.code != 200
        callback({ code: body.code })
      else
        callback(null, body.body)

exports.parseOrigin = (url) ->
  a = window.document.createElement 'a'
  a.href = url
  a.protocol + '//' + a.host

exports.parsePath = (url) ->
  a = window.document.createElement 'a'
  a.href = url
  a.pathname + a.search + a.hash

exports.pluck = (array, name) ->
  array.map (x) -> x[name]
