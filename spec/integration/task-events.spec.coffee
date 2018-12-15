'use strict'

process.env.NODE_ENV = 'test'

utils = require './utils'

describe 'Integration: Task Events', ->

  app = null
  todoist = null
  toggl = null
  expect = null

  before utils.before
  afterEach utils.afterEach

  beforeEach ->
    { app, todoist, toggl, expect } = utils.beforeEach()
    toggl.workspace.list.response = [ id: 34 ]
    todoist.project.response = id: 123, name: 'A fancy Project'

  describe 'Toggl project does not exist', ->

    beforeEach ->
      todoist.project.comments.response = [ project_id: 123, content: 'C' ]

      toggl.project.creation.expectation = (project) ->
        expect(project).to.be.deep.equal
          project:
            name: 'A fancy Project'
            wid: 34

      todoist.comment.creation.expectation = (comment) ->
        expect(comment).to.be.deep.equal
          project_id: 123
          content: ':alarm_clock: [Toggl Timesheet]' +
            '(https://www.toggl.com/app/reports/summary' +
            '/34/period/thisWeek/projects/12)'

    test = (event) ->
      app.send
        event_name: event
        event_data: project_id: 123, content: 'I am an open task'

      .then (response) ->
        toggl.project.creation.request.isDone().should.be.true
        todoist.comment.creation.request.isDone().should.be.true

    it 'should create non-existing Toggle project on task creation', ->
      test 'item:added'

    it 'should create non-existing Toggle project on task update', ->
      test 'item:updated'

  describe 'Toggl project already existing', ->

    beforeEach ->
      todoist.project.comments.response = [
        project_id: 123,
        content: ':alarm_clock: [Toggl Timesheet]' +
          '(https://www.toggl.com/app/reports/summary' +
          '/34/period/thisWeek/projects/12)' ]

    test = (event) ->
      app.send
        event_name: event
        event_data: project_id: 123, content: 'I am an open task'

      .then (response) ->
        toggl.project.creation.request.isDone().should.be.false
        todoist.comment.creation.request.isDone().should.be.false

    it 'should ignore task creation for existing Toggle project', ->
      test 'item:added'

    it 'should ignore task update for existing Toggle project', ->
      test 'item:updated'
