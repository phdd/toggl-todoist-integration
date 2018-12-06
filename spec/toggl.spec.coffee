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

  describe 'consumes Project related Events', ->

    beforeEach ->
      toggl.api = request.defaults()
      toggl.workspaceId = 3134975

    it 'should create a project on a "create project" event', ->
      request.post.returns projectFixture

      toggl.onCreateProject name: 'Test Project'

      request.post.should.have.been.calledOnce
      request.post.should.have.been.calledWithMatch
        uri: '/projects'
        body:
          project:
            wid: 3134975
            name: 'Test Project'

    describe 'Project Archive', ->

      it 'should archive a project on a "archive project" event', ->
        fetchProjects = sinon.stub toggl, 'fetchProjects'
          .returns Promise.resolve(projectsFixture)

        updateProject = sinon.stub toggl, 'updateProject'
          .returns Promise.resolve(projectFixture)

        await toggl.onArchiveProject name: 'Project C'

        fetchProjects.restore()
        updateProject.restore()

        fetchProjects.should.have.been.calledOnce
        updateProject.should.have.been.calledOnce

        updateProject.should.have.been.calledWithMatch
          id: 148091152
          active: false

      it 'should archive nothing if there\'s no such project', ->
        fetchProjects = sinon.stub toggl, 'fetchProjects'
          .returns Promise.resolve(projectsFixture)

        updateProject = sinon.stub toggl, 'updateProject'

        await toggl.onArchiveProject 'This Project does not exist'

        fetchProjects.restore()
        updateProject.restore()

        fetchProjects.should.have.been.calledOnce
        updateProject.should.not.have.been.called

    describe 'Project Deletion', ->
      
      it 'should delete a project on a "delete project" event', ->
        fetchProjects = sinon.stub toggl, 'fetchProjects'
          .returns Promise.resolve(projectsFixture)

        deleteProject = sinon.stub toggl, 'deleteProject'
          .returns Promise.resolve()

        await toggl.onDeleteProject name: 'Project C'

        fetchProjects.restore()
        deleteProject.restore()

        fetchProjects.should.have.been.calledOnce
        deleteProject.should.have.been.calledOnce

        deleteProject.should.have.been.calledWithMatch
          id: 148091152

      it 'should delete nothing if there\'s no such project', ->
        fetchProjects = sinon.stub toggl, 'fetchProjects'
          .returns Promise.resolve(projectsFixture)

        deleteProject = sinon.stub toggl, 'deleteProject'

        await toggl.onDeleteProject 'This Project does not exist'

        fetchProjects.restore()
        deleteProject.restore()

        fetchProjects.should.have.been.calledOnce
        deleteProject.should.not.have.been.called

    describe 'Helper', ->

      it 'should be able to get all workspace projects', ->
        request.get.callsFake (path, callback) ->
          callback null, null, projectsFixture

        projects = await toggl.fetchProjects()

        request.get.should.have.been.calledOnce
        request.get.should.have.been.calledWithMatch
          uri: '/workspaces/3134975/projects'

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
