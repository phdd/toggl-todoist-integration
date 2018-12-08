'use strict'

process.env.NODE_ENV = 'test'

chai = require 'chai'
sinon = require 'sinon'
stubbed = require 'proxyquire'

chai.should()

chai.use require 'sinon-chai'

taskFixture = require './fixtures/todoist-task'

describe 'Todoist', ->

  todoist = null
  request = null

  beforeEach ->
    request =
      get: sinon.stub()
      post: sinon.stub()
      put: sinon.stub()
      del: sinon.stub()
      defaults: sinon.stub()
        .callsFake () -> request

    todoist = stubbed '../lib/todoist',
      'request-promise-native': request

  describe 'Initialization', ->

    it 'should setup the request defaults', ->
      await todoist.init 'TODOIST_API_KEY'

      request.defaults.should.have.been.calledOnce
      request.defaults.should.have.been.calledWith
        json: true
        baseUrl: 'https://beta.todoist.com/API/v8'
        headers:
          Authorization: 'Bearer TODOIST_API_KEY'

  describe 'API Methods', ->

    beforeEach ->
      todoist.api = request.defaults()

    it 'should be able to create tasks', ->
      request.post.returns Promise.resolve(taskFixture)

      task = await todoist.createTask
        name: 'Test Task'

      request.post.should.have.been.calledOnce
      request.post.should.have.been.calledWithMatch
        uri: '/tasks'
        body:
          name: 'Test Task'
