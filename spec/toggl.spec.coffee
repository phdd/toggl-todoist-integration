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

  describe 'Project related Event Consumption', ->

    beforeEach ->
      toggl.api = request.defaults()
      toggl.workspaceId = 3134975
    
    describe 'Project Creation', ->

      it 'should create a project', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(null)

        createProject = sinon.stub toggl, 'createProject'
          .returns Promise.resolve(projectFixture)

        await toggl.onCreateProject name: 'Test Project'
        
        findProjectByName.restore()
        createProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been.calledWith 'Test Project'

        createProject.should.have.been.calledOnce
        createProject.should.have.been.calledWithMatch
          name: 'Test Project'

      it 'should not create the project if it exists already', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(projectFixture)

        createProject = sinon.stub toggl, 'createProject'

        await toggl.onCreateProject name: 'An awesome project'

        findProjectByName.restore()
        createProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been
          .calledWith 'An awesome project'

        createProject.should.not.have.been.called

    describe 'Project Archive', ->

      it 'should archive a project', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(projectFixture.data)

        updateProject = sinon.stub toggl, 'updateProject'
          .returns Promise.resolve(projectFixture)

        await toggl.onArchiveProject name: 'Project C'

        findProjectByName.restore()
        updateProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been.calledWith 'Project C'

        updateProject.should.have.been.calledOnce
        updateProject.should.have.been.calledWithMatch
          id: 3134975
          active: false

      it 'should archive nothing if there\'s no such project', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(null)

        updateProject = sinon.stub toggl, 'updateProject'

        await toggl.onArchiveProject name: 'This Project does not exist'

        findProjectByName.restore()
        updateProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been
          .calledWith 'This Project does not exist'

        updateProject.should.not.have.been.called

    describe 'Project Deletion', ->

      deleteProject = null

      beforeEach ->
        deleteProject = sinon.stub toggl, 'deleteProject'
          .returns Promise.resolve()

      afterEach ->
        deleteProject.restore()

      it 'should delete a project on a "delete project" event', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(projectFixture.data)

        await toggl.onDeleteProject name: 'Project C'

        findProjectByName.restore()

        findProjectByName.should.have.been.calledOnce
        deleteProject.should.have.been.calledOnce

        deleteProject.should.have.been.calledWithMatch
          id: 3134975

      it 'should delete nothing if there\'s no such project', ->
        project = name: 'This Project does not exist'
        
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(null)

        await toggl.onDeleteProject project

        findProjectByName.restore()

        findProjectByName.should.have.been.calledOnce
        deleteProject.should.not.have.been.called

        findProjectByName.should.have.been.calledWith project.name

  describe 'Helper', ->

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

    describe 'Project discovery', ->

      fetchProjects = null

      beforeEach ->
        fetchProjects = sinon.stub toggl, 'fetchProjects'
          .returns Promise.resolve(projectsFixture)

      afterEach ->
        fetchProjects.restore()

      it 'should be able to find projects by name', ->
        await toggl.findProjectByName 'Project C'
          .then (project) ->
            project.id.should.be.equal 148091152

        fetchProjects.should.have.been.calledOnce
      
      it 'should return nothing if there\'s no such project', ->
        await toggl.findProjectByName 'This is no such Project'
          .then (project) ->
            should.not.exist project

        fetchProjects.should.have.been.calledOnce
