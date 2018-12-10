'use strict'

process.env.NODE_ENV = 'test'

chai = require 'chai'
sinon = require 'sinon'
stubbed = require 'proxyquire'

chai.should()

chai.use require 'sinon-chai'

commentsFixture = require './fixtures/todoist-project-comments'

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
      await todoist.init 'TODOIST_API_TOKEN'

      request.defaults.should.have.been.calledOnce
      request.defaults.should.have.been.calledWith
        json: true
        baseUrl: 'https://beta.todoist.com/API/v8'
        headers:
          Authorization: 'Bearer TODOIST_API_TOKEN'

  describe 'API Methods', ->

    beforeEach ->
      todoist.api = request.defaults()

    it 'should be able to create comments', ->
      request.post.returns Promise.resolve
        .callsFake (request) -> request.body

      await todoist.createComment
        project_id: 354
        name: 'Test Comment'

      request.post.should.have.been.calledOnce
      request.post.should.have.been.calledWithMatch
        uri: '/comments'
        body:
          project_id: 354
          name: 'Test Comment'

    it 'should fetch project comments', ->
      request.get.returns Promise.resolve(commentsFixture)

      comments = await todoist.fetchProjectComments 129
      
      request.get.should.have.been.calledOnce
      request.get.should.have.been.calledWith '/comments?project_id=129'

      comments.should.be.equal commentsFixture
