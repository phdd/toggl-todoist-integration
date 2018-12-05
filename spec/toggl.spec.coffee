'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require 'chai'
sinon = require 'sinon'

chai.should()
chai.use require('sinon-chai')
require 'mocha-sinon'

toggl = require '../lib/toggl.js'
workspaces = require './fixtures/toggl-workspaces.json'
projectFixture = require './fixtures/toggl-project.json'
projectsFixture = require './fixtures/toggl-projects.json'

describe 'Toggl', ->

  beforeEach ->
    sinon.stub request, 'get'
    sinon.stub request, 'post'
    sinon.stub request, 'put'
    sinon.spy request, 'defaults'

  afterEach ->
    request.get.restore()
    request.post.restore()
    request.put.restore()
    request.defaults.restore()

  describe 'Initialization', ->

    it 'should setup the request defaults', ->
      request.get.returns workspaces

      toggl.init 'SECRET_KEY'
      
      request.defaults.should.have.been.calledWith
        json: true
        baseUrl: 'https://www.toggl.com/api/v8'
        headers:
          Authorization: 'Basic U0VDUkVUX0tFWTphcGlfdG9rZW4='

    it 'should use the first workspace available', ->
      request.get.callsFake (path, callback) ->
        callback null, null, workspaces

      await toggl.init 'SECRET_KEY'

      request.get.should.have.been.calledWithMatch uri: '/workspaces'
      toggl.workspaceId.should.be.equal 3134975

  describe 'consumes Project related Events', ->

    beforeEach ->
      toggl.api = request.defaults()
      toggl.workspaceId = 3134975

    it 'should create a project on a "create project" event', ->
      request.post.returns projectFixture

      toggl.onCreateProject name: 'Test Project'

      request.post.should.have.been.calledWithMatch
        uri: '/projects'
        body:
          project:
            wid: 3134975
            name: 'Test Project'

    xit 'should archive a project on a "archive project" event', ->

    describe 'Helper', ->

      it 'should be able to get all workspace projects', ->
        request.get.callsFake (path, callback) ->
          callback null, null, projectsFixture

        projects = await toggl.fetchProjects()

        request.get.should.have.been.calledWithMatch
          uri: '/workspaces/3134975/projects'

        projects.should.be.equal projectsFixture
        
      xit 'should be able to update projects', ->
