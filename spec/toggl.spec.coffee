'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require 'chai'
sinon = require 'sinon'
expect = chai.should()

chai.use require('sinon-chai')
require 'mocha-sinon'

toggl = require '../lib/toggl.js'
workspaces = require './fixtures/toggl-workspaces.json'
project = require './fixtures/toggl-project.json'

togglUrl = 'https://www.toggl.com/api/v8'

describe 'Toggl', ->

  beforeEach ->
    sinon.stub request, 'get'
    sinon.stub request, 'post'

  afterEach ->
    request.get.restore()
    request.post.restore()

  describe 'Initialization', ->

    it 'should use the first available workspace and setup authorization', ->
      request.get.returns workspaces
      toggl.init 'SECRET_KEY'
      
      request.get.should.have.been.calledWith
        url: "#{togglUrl}/workspaces",
        Authorization: 'SECRET_KEY:api_token'

      toggl.requestOptions.Authorization.should.be.equal 'SECRET_KEY:api_token'
      toggl.workspaceId.should.be.equal 3134975

  describe 'as Event Consumer', ->

    beforeEach ->
      toggl.requestOptions.Authorization = 'SECRET_KEY:api_token'
      toggl.workspaceId = 3134975

    describe 'Project related Events', ->

      it 'should create a project on a "create project event"', ->
        request.post.returns project
        toggl.onCreateProject name: 'Test Project'
        request.post.should.have.been.calledWith
          Authorization: 'SECRET_KEY:api_token'
          url: "#{togglUrl}/projects"
          body:
            name: 'Test Project'
