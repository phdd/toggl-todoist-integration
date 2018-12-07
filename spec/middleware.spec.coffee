'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require 'chai'
sinon = require 'sinon'

should = chai.should()
chai.use require('sinon-chai')
require 'mocha-sinon'

middleware = require '../lib/middleware.js'

describe 'Middleware', ->

  secretsFor = null
  next = null

  beforeEach ->
    next = sinon.stub()

    secretsFor = sinon.stub middleware, 'secretsFor'
      .returns
        todoistApiKey: 'TODOIST_API_KEY'
        togglApiKey: 'TOGGL_API_KEY'
        todoistClientSecret: 'TODOIST_CLIENT_SECRET'

  afterEach ->
    secretsFor.restore()

  describe 'Initialization', ->

    it 'should initialize Toggl and Todoist once', ->
      toggl = init: sinon.stub().returns Promise.resolve()
      rules = init: sinon.stub().returns Promise.resolve()

      await middleware.init(toggl, rules)(null, null, next)
      await middleware.init(toggl, rules)(null, null, next)

      next.should.have.been.calledTwice

      toggl.init.should.have.been.calledOnce
      toggl.init.should.have.been.calledWith 'TOGGL_API_KEY'

      rules.init.should.have.been.calledOnce
      rules.init.should.have.been.calledWith toggl

  describe 'Request Validation', ->

    request = null
    response = null

    beforeEach ->
      response = status: sinon.stub()
      request = rawBody: JSON.stringify
        event_name: 'project:added'
        event_data:
          id: 123
          name: 'Test Project'

    it 'should allow signed requests', ->
      request.get = sinon.stub()
        .returns 'fiEr99knpRCu9t+ZBXyJAG1jr2q5Qe5pdZ2N/V9oURI='

      middleware.todoistRequestValidation request, response, next

      next.should.have.been.calledOnce

      request.get.should.have.been.calledOnce
      request.get.should.have.been.calledWith 'X-Todoist-Hmac-SHA256'

    it 'should ignore unsigned requests', ->
      request.get = sinon.stub().returns undefined

      middleware.todoistRequestValidation request, response, next

      response.status.should.have.been.calledOnce
      response.status.should.have.been.calledWith 403

    it 'should ignore invalid request signatures', ->
      request.get = sinon.stub().returns '0815'

      middleware.todoistRequestValidation request, response, next

      next.should.not.have.been.called

      response.status.should.have.been.calledOnce
      response.status.should.have.been.calledWith 403

  describe 'Todoist Event Filter', ->

    xit 'should ignore events already consumed', ->
