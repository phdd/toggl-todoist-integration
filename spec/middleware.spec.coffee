'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require 'chai'
sinon = require 'sinon'

should = chai.should()
chai.use require('sinon-chai')
require 'mocha-sinon'

middleware = require '../lib/middleware.js'
# toggl = require '../lib/toggl.js'

describe 'Middleware', ->

  describe 'Initialization', ->

    it 'should initialize toggl once', ->
      next = sinon.stub()
      toggl = init: sinon.stub().returns Promise.resolve()

      middlewareScretsFor = sinon.stub middleware, 'secretsFor'
        .returns togglApiKey: 'SECRET_KEY'

      await middleware.init(toggl)(null, null, next)
      await middleware.init(toggl)(null, null, next)

      middlewareScretsFor.restore()

      next.should.have.been.calledTwice

      toggl.init.should.have.been.calledOnce
      toggl.init.should.have.been.calledWith 'SECRET_KEY'

  describe 'Request Validation', ->

    xit 'should allow signed requests', ->

    xit 'should ignore unsigned requests', ->

  describe 'Todoist Event Filter', ->

    xit 'should ignore events already consumed', ->
