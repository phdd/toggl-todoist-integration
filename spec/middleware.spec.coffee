'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require 'chai'
sinon = require 'sinon'

should = chai.should()
chai.use require('sinon-chai')
require 'mocha-sinon'

toggl = require '../lib/middleware.js'

describe 'Middleware', ->

  describe 'Initialization', ->

    xit 'should initialize toggl', ->

  describe 'Request Validation', ->

    xit 'should allow signed requests', ->

    xit 'should ignore unsigned requests', ->

  describe 'Todoist Event Filter', ->

    xit 'should ignore events already consumed', ->
