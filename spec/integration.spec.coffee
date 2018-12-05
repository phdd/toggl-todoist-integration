'use strict'

process.env.NODE_ENV = 'test'

nock = require 'nock'
chai = require 'chai'
request = require 'supertest'

app = require '../app'
workspaces = require './fixtures/toggl-workspaces.json'

chai.should()

describe 'Integration', ->

  beforeEach ->
    nock /toggl\.com/
      .get /workspaces/
      .reply 200, workspaces

  it 'should tell on unknown events', ->
    await request app
      .post '/todoist-event'
      .send
        event_name: 'something:stupid'
        event_data: 'DATA'
      .then (response) ->
        response.statusCode.should.be.equal 200
        response.body.warn
          .should.be.equal 'Event "something:stupid" cannot be handled'

  describe 'Project related Integration', ->

    it 'should create Toggl Project on Todoist Project Creation', ->
      togglProjectCreation =
        nock /toggl\.com/
          .post /projects/
          .reply 201, (path, container) ->
            data: container.project

      await request app
        .post '/todoist-event'
        .send
          event_name: 'project:added'
          event_data:
            name: 'Test Project'

        .then (response) ->
          project = response.body.data
          togglProjectCreation.isDone()

          response.statusCode.should.be.equal 200
          project.name.should.be.equal 'Test Project'
          project.wid.should.be.equal 3134975
