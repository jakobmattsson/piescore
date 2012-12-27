async = require 'async'
_s = require 'underscore.string'
_ = require 'underscore'

_.mixin require 'underscore.plus'

exports.submodules = {}

## browser

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
  _(element.children).toArray().forEach (x) ->
    element.removeChild(x)

exports.replaceChildren = (id, node) ->
  parent = window.document.getElementById id
  exports.removeChildren parent
  parent.appendChild node

exports.parseOrigin = (url) ->
  a = window.document.createElement 'a'
  a.href = url
  a.protocol + '//' + a.host

exports.parsePath = (url) ->
  a = window.document.createElement 'a'
  a.href = url
  a.pathname + a.search + a.hash




# dunno

exports.block = (f) -> f()




exports.mapObjectAsync = (obj, f, callback) ->
  kvs = _(obj).toKeyValues()
  async.map _.pluck(kvs, 'value'), f, (err, data) ->
    return callback(err) if err
    zipped = _.zip(kvs, data)
    result = _(zipped).toObject(((x) -> x[0].key), '1')
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
