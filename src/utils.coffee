_ = require 'underscore'


# TODO: think about how to handle timezones (and
# whether there's any need to)
exports.inferDate = (sets...) ->
    set = _.extend {}, sets...
    {datetime, date, time, year, month, day, hours, minutes, seconds} = set
    
    time ?= [hours or '00', minutes or '00', seconds or '00'].join ':'

    if datetime
        inferred = new Date datetime
    else if date
        inferred = new Date "#{date} #{time}"
    else if year and month and day
        date = [year, month, day].join '-'
        inferred = new Date "#{date} #{time}"

    if inferred and not isNaN inferred.valueOf()
        inferred
    else
        null


# remove keys from an object if their value is undefined, 
# similar to what _.compact does for an array
exports.compactObject = _.partial _.pick, _, (_.negate _.isUndefined)


exports.optional = (options) ->
    if options.length
        options[0]
    else
        {}


exports.seed = (args...) ->
    (callback) ->
        callback null, args...


exports.callback = (fn) ->
    (args..., callback) ->
        callback null, fn args...


exports.underscored = (obj) ->
    _.object _.map obj, (value, key) ->
        ['_' + key, value]
