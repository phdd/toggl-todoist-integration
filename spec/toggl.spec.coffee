'use strict'

process.env.NODE_ENV = 'test'

chai = require 'chai'
sinon = require 'sinon'
stubbed = require 'proxyquire'

chai.use require 'sinon-chai'

should = chai.should()

workspaces = require './fixtures/toggl-workspaces.json'
projectFixture = require './fixtures/toggl-project.json'
projectsFixture = require './fixtures/toggl-projects.json'

describe 'Toggl', ->

  toggl = null
  request = null

  beforeEach ->
    request =
      get: sinon.stub()
      post: sinon.stub()
      put: sinon.stub()
      del: sinon.stub()
      defaults: sinon.stub()
        .callsFake () -> request

    toggl = stubbed '../lib/toggl',
      'request-promise-native': request

  describe 'Initialization', ->

    it 'should setup the request defaults', ->
      request.get.returns Promise.resolve(workspaces)

      toggl.init 'SECRET_KEY'

      request.defaults.should.have.been.calledOnce
      request.defaults.should.have.been.calledWith
        json: true
        baseUrl: 'https://www.toggl.com/api/v8'
        headers:
          Authorization: 'Basic U0VDUkVUX0tFWTphcGlfdG9rZW4='

    it 'should use the first workspace available', ->
      request.get.returns Promise.resolve(workspaces)

      await toggl.init 'SECRET_KEY'

      request.get.should.have.been.calledOnce
      request.get.should.have.been.calledWithMatch '/workspaces'
      toggl.workspaceId.should.be.equal 3134975

  describe 'API Methods', ->

    beforeEach ->
      toggl.api = request.defaults()
      toggl.workspaceId = 3134975

    it 'should be able to create projects', ->
      request.post.returns Promise.resolve(projectFixture)

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
      request.get.returns Promise.resolve(projectsFixture)

      projects = await toggl.fetchProjects()

      request.get.should.have.been.calledOnce
      request.get.should.have.been
        .calledWith '/workspaces/3134975/projects?active=both'

      projects.should.be.equal projectsFixture
      
    it 'should be able to update projects', ->
      request.put.returns Promise.resolve(projectFixture)

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
      request.get.returns Promise.resolve(projectsFixture)
      request.del.returns Promise.resolve(null)

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

    describe 'Helper Methods', ->

      it 'should be able to build a report frontend link', ->
        link = toggl.buildProjectReportLinkFor
          id: 123
          wid: 456

        link.should.be.equal 'https://www.toggl.com/app/' +
                             'reports/summary/456/' +
                             'period/thisWeek/projects/123'

      it 'should be able to extract a project ids from report links', ->
        link = 'https://www.toggl.com/app/reports/summary/3134975/' +
               'period/thisWeek/projects/148091152'

        projectId = toggl.projectIdFrom link

        projectId.should.be.equal 148091152

      it 'should not be able to extract a project ids' +
         'from invalid report links', ->
        link = 'https://google.de'

        projectId = toggl.projectIdFrom link

        chai.expect(projectId).to.be.equal null
