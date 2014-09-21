program = require 'commander'
fs = require 'fs'
fs.path = require 'path'
gather = require './'

program
    .usage '<directory> [options]'
    .option '-o, --output <path>', 
        'Write the gathered data to a file.'
    .option '-r, --raw', 
        'Do not add any metadata, keep the JSON as-is.'
    .option '-a --annotate', 
        'Merge in additional metadata about the file.'
    .option '-s --scheme [compact|underscored|extended]', 
        'The naming scheme for metadata fields [compact].', 'compact'
    .option '-f, --force',
        'Do not attempt to use any existing file at --output as a cache.'
    .option '-I, --indent [n]', 
        'Indent the output JSON.', parseInt, 2
    .parse process.argv


if program.raw and program.annotate
    throw new Error "Cannot output raw and annotated data at the same time. Choose one."

source = program.args[0]
destination = program.output

options =
    raw: program.raw
    annotate: program.annotate
    scheme: program.scheme
    cache: if program.force then no else destination

gather source, options, (err, data) ->
    serialization = JSON.stringify data, undefined, program.indent
    
    if destination
        fs.writeFileSync destination, serialization, encoding: 'utf8'
    else
        console.log serialization
