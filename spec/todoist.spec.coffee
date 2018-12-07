'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require('chai')
sinon = require('sinon')

chai.should()

chai.use require('chai-as-promised')
chai.use require('sinon-chai')

require 'mocha-sinon'

rules = require '../lib/rules'
toggl = require '../lib/toggl'

projectFixture = require './fixtures/toggl-project.json'

describe 'Todoist', ->

  describe 'Initialization', ->
    
    xit 'should do something', ->

  describe 'API Methods', ->

    xit 'should do something', ->
