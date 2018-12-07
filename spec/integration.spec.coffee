'use strict'

process.env.NODE_ENV = 'test'

nock = require 'nock'
chai = require 'chai'
request = require 'supertest'
sinon = require 'sinon'

app = null
middleware = require '../lib/middleware'
workspacesFixture = require './fixtures/toggl-workspaces.json'
projectsFixture = require './fixtures/toggl-projects.json'
projectFixture = require './fixtures/toggl-projects.json'

chai.should()

describe 'Integration', ->

  togglWorkspaceFetching = null
  todoistRequestValidation = null
  secretsFor = null
  
  before ->
    todoistRequestValidation = sinon.stub middleware, 'todoistRequestValidation'
      .callsFake (request, response, next) -> next()
    
    secretsFor = sinon.stub middleware, 'secretsFor'
      .returns
        todoistApiKey: 'TODOIST_API_KEY'
        togglApiKey: 'TOGGL_API_KEY'
        todoistClientSecret: 'TODOIST_CLIENT_SECRET'

    app = require '../app'

  after ->
    todoistRequestValidation.restore()
    secretsFor.restore()

  beforeEach ->
    togglWorkspaceFetching = nock /toggl\.com/
      .get /workspaces/
      .reply 200, workspacesFixture

  afterEach ->
    middleware.hasBeenInitialized = false
    nock.cleanAll()

  it 'should tell on unknown events', ->
    await request app
      .post '/todoist-event'
      .send
        event_name: 'something:stupid'
        event_data: 'DATA'
      .then (response) ->
        togglWorkspaceFetching.isDone().should.be.true

        response.statusCode.should.be.equal 200
        response.body.warn
          .should.be.equal 'Event "something:stupid" cannot be handled'

  describe 'Project related Integration', ->

    togglProjectFetching = null
    togglProjectUpdate = null
    togglProjectCreation = null

    beforeEach ->
      togglProjectFetching =
        nock /toggl\.com/
          .get /workspaces\/.+\/projects/
          .reply 200, projectsFixture

      togglProjectUpdate =
        nock /toggl\.com/
          .put /projects\/.+/
          .reply 200, (path, container) ->
            return data: container.project

      togglProjectCreation =
        nock /toggl\.com/
          .post /projects/
          .reply 201, (path, container) ->
            data: container.project

    describe 'Project created event reaction', ->

      it 'should create Toggl Project on Todoist Project Creation', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:added'
            event_data:
              id: 123
              name: 'Test Project'

          .then (response) ->
            project = response.body.data
            togglProjectCreation.isDone().should.be.true

            response.statusCode.should.be.equal 200
            project.name.should.be.equal 'Test Project (123)'
            project.wid.should.be.equal 3134975

      it 'should not do anything if there\'s already a project on Toggl', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:added'
            event_data:
              id: 123
              name: 'An awesome project'

          .then (response) ->
            togglProjectFetching.isDone().should.be.true
            togglProjectCreation.isDone().should.be.false

            response.statusCode.should.be.equal 200
            response.body.should.be.empty

    describe 'Project archived event reaction', ->

      it 'should archive a Toggl Project when Todoist does', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:archived'
            event_data:
              id: 123
              name: 'Project C'

          .then (response) ->
            project = response.body.data
            togglProjectFetching.isDone().should.be.true
            togglProjectUpdate.isDone().should.be.true

            response.statusCode.should.be.equal 200
            project.id.should.be.equal 148091152
            project.active.should.be.false

      it 'should not do anything if there\'s no such project on Toggl', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:archived'
            event_data:
              id: 123
              name: 'I am no such Project'

          .then (response) ->
            togglProjectFetching.isDone().should.be.true
            togglProjectUpdate.isDone().should.be.false

            response.statusCode.should.be.equal 200
            response.body.should.be.empty

    describe 'Project deleted event reaction', ->

      togglProjectDeletion = null

      beforeEach ->
        togglProjectDeletion =
          nock /toggl\.com/
            .delete /projects/
            .reply 200, null

      it 'should delete a Toggl Project when Todoist does', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:deleted'
            event_data:
              id: 123
              name: 'Project C'

          .then (response) ->
            togglProjectFetching.isDone().should.be.true
            togglProjectDeletion.isDone().should.be.true

            response.body.should.be.empty
            response.statusCode.should.be.equal 200

      it 'should not do anything if there\'s no such project on Toggl', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:deleted'
            event_data:
              id: 123
              name: 'I am no such Project'

          .then (response) ->
            togglProjectFetching.isDone().should.be.true
            togglProjectDeletion.isDone().should.be.false

            response.statusCode.should.be.equal 200
            response.body.should.be.empty

    describe 'Project unarchived event reaction', ->

      it 'should restore a Toggl Project when Todoist does', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:unarchived'
            event_data:
              id: 123
              name: 'Project C'

          .then (response) ->
            project = response.body.data
            togglProjectFetching.isDone().should.be.true
            togglProjectUpdate.isDone().should.be.true

            response.statusCode.should.be.equal 200
            project.id.should.be.equal 148091152
            project.active.should.be.true

      it 'should create a Toggle Project if it does not exist', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:unarchived'
            event_data:
              id: 123
              name: 'I am no such Project'

          .then (response) ->
            togglProjectFetching.isDone().should.be.true
            togglProjectUpdate.isDone().should.be.false
            togglProjectCreation.isDone().should.be.true

            project = response.body.data

            response.statusCode.should.be.equal 200
            project.name.should.be.equal 'I am no such Project (123)'
            project.wid.should.be.equal 3134975
