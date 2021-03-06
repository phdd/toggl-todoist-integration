'use strict'

process.env.NODE_ENV = 'test'

nock = require 'nock'
chai = require 'chai'
request = require 'supertest'
sinon = require 'sinon'

workspacesFixture = require './fixtures/toggl-workspaces'
projectsFixture = require './fixtures/toggl-projects'
projectFixture = require './fixtures/toggl-projects'
commentsFixture = require './fixtures/todoist-project-comments'

chai.should()

nock.disableNetConnect()
nock.enableNetConnect /127\.0\.0\.1/

describe 'Integration: Project Events', ->

  app = null
  middleware = null

  togglWorkspaceFetching = null
  todoistRequestValidation = null
  secretsFor = null
  
  before ->
    middleware = require '../lib/middleware'

    log = require '../lib/log'
    log.toConsole = sinon.stub()

    todoistRequestValidation = sinon.stub middleware, 'todoistRequestValidation'
      .callsFake (request, response, next) -> next()
    
    secretsFor = sinon.stub middleware, 'secretsFor'
      .returns
        todoistApiToken: 'TODOIST_API_TOKEN'
        togglApiToken: 'TOGGL_API_TOKEN'
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
    todoistTaskCreation = null
    todoistCommentFetching = null
    todoistEmptyCommentFetching = null
    todoistCommentCreation = null

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
            container.project.id = 7673435
            data: container.project

      todoistTaskCreation =
        nock /todoist\.com/
          .post /tasks/
          .reply 201, (path, task) -> task

      todoistCommentCreation =
        nock /todoist\.com/
          .post /comments/
          .reply 201, (path, comment) -> comment

      todoistCommentFetching =
        nock /todoist\.com/
          .get /comments\?project_id=129/
          .reply 200, commentsFixture

      todoistEmptyCommentFetching =
        nock /todoist\.com/
          .get /comments\?project_id=5468/
          .reply 200, []

    describe 'Project updated event reaction', ->

      it 'should update existing Toggle project', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:updated'
            event_data:
              id: 129
              name: 'Project C is even better'

          .then (response) ->
            project = response.body
            todoistCommentFetching.isDone().should.be.true
            togglProjectUpdate.isDone().should.be.true

            response.statusCode.should.be.equal 200
            project.id.should.be.equal 148091152
            project.name.should.be.equal 'Project C is even better'

      it 'should create non-existing Toggle project', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:updated'
            event_data:
              id: 5468
              name: 'I am no such Project'

          .then (response) ->
            todoistEmptyCommentFetching.isDone().should.be.true
            togglProjectUpdate.isDone().should.be.false
            togglProjectCreation.isDone().should.be.true

            response.statusCode.should.be.equal 200

            response.body.togglProject.name
              .should.be.equal 'I am no such Project'

            response.body.togglProject.wid.should.be.equal 3134975

    describe 'Project added event reaction', ->

      it 'should create Toggl Project on Todoist Project Creation', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:added'
            event_data:
              id: 468498431
              name: 'Test Project'

          .then (response) ->
            project = response.body.togglProject
            comment = response.body.todoistComment

            togglProjectCreation.isDone().should.be.true
            todoistCommentCreation.isDone().should.be.true

            response.statusCode.should.be.equal 200

            project.name.should.be.equal 'Test Project'
            project.wid.should.be.equal 3134975

            comment.project_id.should.be.equal 468498431
            comment.content.should.be.equal ':alarm_clock: [Toggl Timesheet]' +
              '(https://www.toggl.com/app/reports/summary/3134975/' +
              'period/thisWeek/projects/7673435)'

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
              id: 129
              name: 'Project C'

          .then (response) ->
            project = response.body
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
              id: 129
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
              id: 129
              name: 'Project C'

          .then (response) ->
            project = response.body
            todoistCommentFetching.isDone().should.be.true
            togglProjectUpdate.isDone().should.be.true
            togglProjectCreation.isDone().should.be.false

            response.statusCode.should.be.equal 200
            project.id.should.be.equal 148091152
            project.active.should.be.true

      it 'should create a Toggle Project if it does not exist', ->
        await request app
          .post '/todoist-event'
          .send
            event_name: 'project:unarchived'
            event_data:
              id: 5468
              name: 'I am no such Project'

          .then (response) ->
            todoistEmptyCommentFetching.isDone().should.be.true
            todoistCommentCreation.isDone().should.be.true
            togglProjectUpdate.isDone().should.be.false
            togglProjectCreation.isDone().should.be.true

            response.statusCode.should.be.equal 200

            response.body.togglProject.name
              .should.be.equal 'I am no such Project'

            response.body.togglProject.wid.should.be.equal 3134975
