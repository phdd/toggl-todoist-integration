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
options = Authorization: 'SECRET_KEY:api_token'

describe 'Toggl', ->

  beforeEach ->
    sinon.stub request, 'get'
    sinon.stub request, 'post'

  afterEach ->
    request.get.restore()
    request.post.restore()

  describe 'Initialization', ->
    it 'should use the first available workspace', ->
      request.get.returns workspaces
      toggl.init 'SECRET_KEY'
      request.get.should.have.been.calledWith "#{togglUrl}/workspaces", options

  describe 'as Event Consumer', ->

    describe 'Project related Events', ->

      it 'should create a project on a "create project event"', ->
        request.post.returns project
        toggl.onCreateProject name: 'Test Project'
        request.post.should.have.been.calledWith "#{togglUrl}/projects", options
