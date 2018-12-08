'use strict'

process.env.NODE_ENV = 'test'

chai = require 'chai'
sinon = require 'sinon'
stubbed = require 'proxyquire'

chai.should()

chai.use require 'chai-as-promised'
chai.use require 'sinon-chai'

projectFixture = require './fixtures/toggl-project.json'
projectsFixture = require './fixtures/toggl-projects.json'
taskFixture = require './fixtures/todoist-task.json'

describe 'Rules', ->

  rules = null
  todoist = null
  toggl = null

  beforeEach ->
    todoist = {}
    toggl = {}

    rules = stubbed '../lib/rules',
      './log':
        info: ->
        warn: ->
        error: ->

  describe 'Event Forwarding', ->

    it 'should consume valid events', ->
      projectAdded = sinon.stub rules, 'project_added'
        .callsFake (data) -> Promise.resolve(data)

      rules.forward event_name: 'project:added', event_data: 'Hi there!'
        .should.eventually.be.equal 'Hi there!'

      projectAdded.restore()

      projectAdded.should.have.been.calledOnce

    it 'should tell on invalid events', ->
      rules.forward {}
        .should.be.rejectedWith 'no valid event_name attribute defined'

    it 'should tell on unknown events', ->
      rules.forward { event_name: 'do:this' }
        .should.be.rejectedWith 'Event "do:this" cannot be handled'

  describe 'Reaction on Project Events', ->

    todoist = {}

    beforeEach ->
      toggl.workspaceId = 3134975
      rules.init toggl, todoist

    describe 'project:added', ->

      it 'should create a project', ->
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(null)

        toggl.createProject = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        await rules.project_added id: 123, name: 'Test Project'

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.findProjectByName.should.have.been
          .calledWith 'Test Project (123)'

        toggl.createProject.should.have.been.calledOnce
        toggl.createProject.should.have.been
          .calledWith name: 'Test Project (123)'

      it 'should not create the project if it exists already', ->
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        toggl.createProject = sinon.stub()

        await rules.project_added id: 123, name: 'An awesome project'

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.findProjectByName.should.have.been
          .calledWith 'An awesome project (123)'

        toggl.createProject.should.not.have.been.called

    describe 'project:archive', ->

      it 'should archive a project', ->
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        toggl.updateProject = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        await rules.project_archived id: 123, name: 'Project C'

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.findProjectByName.should.have.been.calledWith 'Project C (123)'

        toggl.updateProject.should.have.been.calledOnce
        toggl.updateProject.should.have.been.calledWithMatch
          id: 3134975
          active: false

      it 'should archive nothing if there\'s no such project', ->
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(null)

        toggl.updateProject = sinon.stub()

        await rules.project_archived
          id: 123, name: 'This Project does not exist'

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.findProjectByName.should.have.been
          .calledWith 'This Project does not exist (123)'

        toggl.updateProject.should.not.have.been.called

    describe 'project:unarchived', ->

      it 'should restore a project', ->
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        toggl.updateProject = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        await rules.project_unarchived id: 123, name: 'Project C'

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.findProjectByName.should.have.been.calledWith 'Project C (123)'

        toggl.updateProject.should.have.been.calledOnce
        toggl.updateProject.should.have.been.calledWithMatch
          id: 3134975
          active: true

      it 'should create a project if it does not exist', ->
        projectCreationRulesFor = sinon.stub rules, 'projectCreationRulesFor'

        toggl.updateProject = sinon.stub()
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(null)

        await rules.project_unarchived
          id: 113, name: 'This Project does not exist'

        projectCreationRulesFor.restore()

        toggl.updateProject.should.not.have.been.called

        projectCreationRulesFor.should.have.been.calledOnce
        projectCreationRulesFor.should.have.been
          .calledWith { id: 113, name: 'This Project does not exist' },
                      { name: 'This Project does not exist (113)' }

    describe 'project:deleted', ->

      beforeEach ->
        toggl.deleteProject = sinon.stub()
          .returns Promise.resolve()

      it 'should delete a project', ->
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        await rules.project_deleted id: 123, name: 'Project C'

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.deleteProject.should.have.been.calledOnce

        toggl.deleteProject.should.have.been.calledWithMatch
          id: 3134975

      it 'should delete nothing if there\'s no such project', ->
        project = id: 123, name: 'This Project does not exist'
        
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(null)

        await rules.project_deleted project

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.deleteProject.should.not.have.been.called

        toggl.findProjectByName.should.have.been
          .calledWith 'This Project does not exist (123)'

    describe 'project:updated', ->

      it 'should update an existing project', ->
        toggl.fetchProjects = sinon.stub()
          .returns Promise.resolve(projectsFixture)
        toggl.updateProject = sinon.stub()
          .returns Promise.resolve(projectFixture)

        result = await rules.project_updated id: 123, name: 'An awesome project'

        toggl.fetchProjects.should.have.been.calledOnce
        toggl.updateProject.should.have.been.calledOnce
        toggl.updateProject.should.have.been.calledWithMatch
          id: 3134975
          name: 'An awesome project (123)'

        result.should.be.equal projectFixture

      it 'should create a non-existing project', ->
        projectCreationRulesFor = sinon.stub rules, 'projectCreationRulesFor'

        toggl.createProject = sinon.stub().returns Promise
        toggl.fetchProjects = sinon.stub()
          .returns Promise.resolve(projectsFixture)

        result = await rules.project_updated id: 113, name: 'A project'

        projectCreationRulesFor.restore()

        projectCreationRulesFor.should.have.been.calledOnce
        projectCreationRulesFor.should.have.been
          .calledWith { id: 113, name: 'A project' },
                      { name: 'A project (113)' }

    describe 'item:added', ->

      xit 'should create a project', ->
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(null)

        toggl.createProject = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        await rules.project_added id: 123, name: 'Test Project'

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.findProjectByName.should.have.been
          .calledWith 'Test Project (123)'

        toggl.createProject.should.have.been.calledOnce
        toggl.createProject.should.have.been
          .calledWith name: 'Test Project (123)'

      xit 'should not create the project if it exists already', ->
        toggl.findProjectByName = sinon.stub()
          .returns Promise.resolve(projectFixture.data)

        toggl.createProject = sinon.stub()

        await rules.project_added id: 123, name: 'An awesome project'

        toggl.findProjectByName.should.have.been.calledOnce
        toggl.findProjectByName.should.have.been
          .calledWith 'An awesome project (123)'

        toggl.createProject.should.not.have.been.called

    it 'should create a corresponding ' +
        'todoist task if the project has been created', ->
      todoistTaskDto =
        content: '* [:alarm_clock: Timesheet](report-link)'
        project_id: 1234

      toggl.createProject = sinon.stub()
        .returns Promise.resolve(projectFixture)
      toggl.buildProjectReportLinkFor = sinon.stub()
        .returns Promise.resolve('report-link')
      todoist.createTask = sinon.stub()
        .returns Promise.resolve(todoistTaskDto)

      result = await rules.projectCreationRulesFor { id: 1234 }, projectFixture

      toggl.createProject.should.have.been.calledOnce
      toggl.createProject.should.have.been.calledWith projectFixture

      todoist.createTask.should.have.been.calledOnce
      todoist.createTask.should.have.been.calledWith todoistTaskDto
  
      result.togglProject.should.be.equal projectFixture
      result.todoistTask.should.be.equal todoistTaskDto
