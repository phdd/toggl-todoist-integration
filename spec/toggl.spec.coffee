'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require 'chai'
sinon = require 'sinon'

should = chai.should()
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
    sinon.stub request, 'del'
    sinon.spy request, 'defaults'

  afterEach ->
    request.get.restore()
    request.post.restore()
    request.put.restore()
    request.del.restore()
    request.defaults.restore()

  describe 'Initialization', ->

    it 'should setup the request defaults', ->
      request.get.returns workspaces

      toggl.init 'SECRET_KEY'

      request.defaults.should.have.been.calledOnce
      request.defaults.should.have.been.calledWith
        json: true
        baseUrl: 'https://www.toggl.com/api/v8'
        headers:
          Authorization: 'Basic U0VDUkVUX0tFWTphcGlfdG9rZW4='

    it 'should use the first workspace available', ->
      request.get.callsFake (path, callback) ->
        callback null, null, workspaces

      await toggl.init 'SECRET_KEY'

      request.get.should.have.been.calledOnce
      request.get.should.have.been.calledWithMatch uri: '/workspaces'
      toggl.workspaceId.should.be.equal 3134975

  describe 'API Methods', ->

    beforeEach ->
      toggl.api = request.defaults()
      toggl.workspaceId = 3134975

    it 'should be able to create projects', ->
      request.post.callsFake (path, callback) ->
        callback null, null, projectFixture

      project = await toggl.createProject
        name: 'Test Project'

      request.post.should.have.been.calledOnce
      request.post.should.have.been.calledWithMatch
        uri: '/projects'
        body:
          project:
            wid: 3134975
            name: 'Test Project'

    it 'should be able to get all workspace projects', ->
      request.get.callsFake (path, callback) ->
        callback null, null, projectsFixture

      projects = await toggl.fetchProjects()

      request.get.should.have.been.calledOnce
      request.get.should.have.been.calledWithMatch
        uri: '/workspaces/3134975/projects?active=both'

      projects.should.be.equal projectsFixture
      
    it 'should be able to update projects', ->
      request.put.callsFake (path, callback) ->
        callback null, null, projectFixture

      projects = await toggl.updateProject
        id: 3134975
        active: false

      request.put.should.have.been.calledOnce
      request.put.should.have.been.calledWithMatch
        uri: '/projects/3134975'
        body:
          project:
            active: false

    it 'should be able to delete projects', ->
      request.get.callsFake (path, callback) ->
        callback null, null, projectsFixture

      request.del.callsFake (path, callback) ->
        callback null, null, null

      await toggl.deleteProject
        id: '148091152'

      request.del.should.have.been.calledOnce
      request.del.should.have.been.calledWithMatch
        uri: '/projects/148091152'

    describe 'Project discovery', ->

      fetchProjects = null

      beforeEach ->
        fetchProjects = sinon.stub toggl, 'fetchProjects'
          .returns Promise.resolve(projectsFixture)

      afterEach ->
        fetchProjects.restore()

      it 'should be able to find projects by name', ->
        await toggl.findProjectByName 'Project C (123)'
          .then (project) ->
            project.id.should.be.equal 148091152

        fetchProjects.should.have.been.calledOnce
      
      it 'should return nothing if there\'s no such project', ->
        await toggl.findProjectByName 'This is no such Project'
          .then (project) ->
            should.not.exist project

        fetchProjects.should.have.been.calledOnce
