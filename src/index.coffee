_ = require 'underscore'
fs = require 'fs'
fs.path = require 'path'
fs.find = require 'findit'
async = require 'async'
{PathExp} = require 'simple-path-expressions'
Object.defineProperty Date.prototype, 'expand', value: require 'date-expand'
utils = require './utils'


class FileCache
    constructor: (path) ->
        raw = fs.readFileSync path, encoding: 'utf8'
        candidateFiles = JSON.parse raw

        @files = {}
        for file in candidateFiles
            # we can't cache an object that doesn't 
            # have path or mtime in its metadata
            # (we wouldn't know if it was stale)
            try
                origin = file.origin or file._origin
                path = origin.absolute
                mtime = (new Date origin.mtime).getTime()
            catch
                continue          
            @files[path] = {}
            @files[path][mtime] = file

    get: (stats) ->
        mtime = stats.mtime.getTime()
        @files[stats.absolute]?[mtime]

describeFile = (relativePath, stats) ->
    relative = relativePath
    absolute = fs.path.resolve relative
    basename = fs.path.basename relative
    extension = fs.path.extname relative
    path = {absolute, relative, basename, extension}
    _.extend path, stats

readJSON = (path, callback) ->
    fs.readFile path, {encoding: 'utf8'}, (err, raw) ->
        data = if not err then JSON.parse raw
        callback err, data

findFiles = (root, callback) ->
    files = []
    finder = fs.find root
    finder.on 'file', (relativePath, stats) ->
        files.push describeFile relativePath, stats
    finder.on 'end', ->
        callback null, files

matchFiles = (route, files) ->
    _.compact _.map files, (file) ->
        if metadata = route.match file.relative
            _.extend file, {metadata}

processFile = (fileDescription, options, callback) ->
    if options.cache and cached = options.cache.get fileDescription
        cached.origin.cached = yes
        return callback null, cached

    metadata = fileDescription.metadata
    origin = _.omit fileDescription, 'metadata'

    date =
        accessed: origin.atime.expand()
        created: origin.ctime.expand()
        modified: origin.mtime.expand()

    readJSON fileDescription.relative, (err, data) ->
        date.inferred = (utils.inferDate data, metadata)?.expand()
        callback err, {origin, date, metadata, data}

processFiles = (fileDescriptions, options, callback) ->
    processFileWithOptions = _.partial processFile, _, options
    async.map fileDescriptions, processFileWithOptions, callback

schemes =
    extended: _.identity

    compact: (item) ->
        {origin, date, metadata, data} = item
        utils.compactObject _.extend {}, 
            {origin}
            {date}
            metadata
            data

    underscored: (item) ->
        meta =
            filename: utils.underscored item.metadata
            file: utils.underscored _.pick item, 'origin', 'date'
        _.extend {}, item.data, meta.filename, meta.file
        

# paths have a root (that they're relative to), 
# a trunk (which does not contain placeholders)
# and leaves (which we will search through)
module.exports = (input, options..., callback) ->
    options = utils.optional options
    _.defaults options, 
        scheme: 'compact'

    route = new PathExp input

    if options.cache and fs.existsSync options.cache
        options.cache = new FileCache options.cache
    else
        options.cache = no

    matchRoute = _.partial matchFiles, route
    processFilesWithOptions = _.partial processFiles, _, options

    steps = [
        (utils.seed route.head)
        findFiles  
        (utils.callback matchRoute)     
        processFilesWithOptions
        ]

    async.waterfall steps, (err, items) ->
        [cached, uncached] = _.partition items, (item) -> item.origin.cached

        if options.raw
            uncached = uncached.map (item) -> item.data
        else if not options.annotate
            uncached = uncached.map (item) ->
                _.pick item, 'data', 'metadata'

        uncached = uncached.map schemes[options.scheme]
        all = cached.concat uncached
        callback err, all
