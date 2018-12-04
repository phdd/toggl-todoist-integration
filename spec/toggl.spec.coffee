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

describe 'Toggl', ->

  beforeEach ->
    sinon.stub request, 'get'
    sinon.stub request, 'post'
    sinon.spy request, 'defaults'

  afterEach ->
    request.get.restore()
    request.post.restore()
    request.defaults.restore()

  describe 'Initialization', ->
    
    it 'should setup the request defaults', ->
      request.get.returns workspaces

      toggl.init 'SECRET_KEY'
      
      request.defaults.should.have.been.calledWith
        json: true
        baseUrl: 'https://www.toggl.com/api/v8'
        headers:
          Authorization: 'SECRET_KEY:api_token'

    it 'should use the first workspace available', ->
      request.get.returns workspaces

      toggl.init 'SECRET_KEY'

      request.get.should.have.been.calledWith matching
        uri: '/workspaces'

      toggl.workspaceId.should.be.equal 3134975

  describe 'consumes Project related Events', ->

    beforeEach ->
      toggl.workspaceId = 3134975

    it 'should create a project on a "create project event"', ->
      request.post.returns project

      toggl.onCreateProject name: 'Test Project'

      request.post.should.have.been.calledWith
        uri: '/projects'
        body:
          wid: 3134975
          name: 'Test Project'
