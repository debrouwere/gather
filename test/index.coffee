_ = require 'underscore'
fs = require 'fs'
{exec} = require 'child_process'
should = require 'should'
gather = require '../src'

describe 'programmatic interface', ->
    it 'can merge objects', (done) ->
        gather 'examples/staff/{lastname}.json', (err, data) ->
            data.length.should.eql 3
            done err

    it 'will include metadata gleaned from filename placeholders', (done) ->
        gather 'examples/staff/{lastname}.json', (err, data) ->
            lastnames = _.pluck data, 'lastname'
            lastnames.should.eql [
                'jones'
                'karlsson'
                'smith'
                ]
            done err

    it 'only provides filename metadata (not file metadata) by default', (done) ->
        options = 
            annotate: no
        gather 'examples/staff/{lastname}.json', options, (err, data) ->
            for obj in data
                obj.should.have.properties [
                    'lastname'
                    ]
                obj.should.not.have.properties [
                    'origin'
                    'date'
                    ]
            done err

    it 'can provided more metadata based on a file its stats', (done) ->
        options = 
            annotate: yes
        gather 'examples/staff/{lastname}.json', options, (err, data) ->
            for obj in data
                obj.date.should.have.properties [
                    'accessed'
                    'created'
                    'modified'
                    ]
                obj.origin.should.have.properties [
                    'relative'
                    'absolute'
                    'basename'
                    'extension'
                    ]
            done err

    it 'can underscore metadata in output', (done) ->
        options =
            annotate: yes
            scheme: 'underscored'
        gather 'examples/staff/{lastname}.json', options, (err, data) ->
            for obj in data
                obj.should.have.properties [
                    '_date'
                    '_origin'
                    '_lastname'
                    'name'
                    ]
            done err

    it 'can keep metadata nicely separate from data in output', (done) ->
        options =
            annotate: yes
            scheme: 'extended'
        gather 'examples/staff/{lastname}.json', options, (err, data) ->
            for obj in data
                obj.should.have.keys [
                    'date'
                    'origin'
                    'data'
                    'metadata'
                    ]
            done err

describe 'command-line interface', ->
    it 'has a command-line interface', (done) ->
        command = "./bin/gather examples/staff/{lastname}.json"
        exec command, (err, stdout, stderr) ->
            data = JSON.parse stdout
            data.length.should.eql 3
            data[2].lastname.should.eql 'smith'
            done err
