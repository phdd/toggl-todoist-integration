'use strict'

process.env.NODE_ENV = 'test'

chai = require 'chai'
sinon = require 'sinon'
stubbed = require 'proxyquire'

should = chai.should()

chai.use require 'sinon-chai'

describe 'Middleware', ->

  middleware = null
  next = null

  mockSecrets =
    todoistApiKey: 'TODOIST_API_KEY'
    togglApiKey: 'TOGGL_API_KEY'
    todoistClientSecret: 'TODOIST_CLIENT_SECRET'

  beforeEach ->
    next = sinon.stub()

    middleware = require '../lib/middleware.js',
      'assert': require 'assert'
      './log':
        info: ->
        warn: ->
        error: ->

  it 'should depend on secrets from Webtask.io', ->
    (() -> middleware.secretsFor {})
      .should.throw Error, 'Webtask.io Secrets Missing'

  it 'should complain about missing secrets', ->
    secretsFor = sinon.stub middleware, 'secretsFor'
      .returns todoistApiKey: 12, togglApiKey: 27
    
    (() -> middleware.init()())
      .should.throw Error, 'Secret "todoistClientSecret" missing'

  describe 'Initialization', ->

    secretsFor = null
    next = null

    beforeEach ->
      secretsFor = sinon.stub middleware, 'secretsFor'
        .returns mockSecrets

    afterEach ->
      secretsFor.restore()

    it 'should initialize Toggl, Todoist and Rules once', ->
      toggl = init: sinon.stub().returns Promise.resolve()
      todoist = init: sinon.stub().returns Promise.resolve()
      rules = init: sinon.stub().returns Promise.resolve()

      firstInit = middleware.init(toggl, todoist, rules)
      secondInit = middleware.init(toggl, todoist, rules)

      await await firstInit(null, null, next)
      await await secondInit(null, null, next)

      next.should.have.been.calledTwice

      toggl.init.should.have.been.calledOnce
      toggl.init.should.have.been.calledWith 'TOGGL_API_KEY'

      todoist.init.should.have.been.calledOnce
      todoist.init.should.have.been.calledWith 'TODOIST_API_KEY'

      rules.init.should.have.been.calledOnce
      rules.init.should.have.been.calledWith toggl

  describe 'Request Validation', ->

    request = null
    response = null

    beforeEach ->
      response = status: sinon.stub()
      request =
        webtaskContext: secrets: mockSecrets
        rawBody: JSON.stringify
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
