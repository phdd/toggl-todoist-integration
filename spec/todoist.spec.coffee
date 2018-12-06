'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require('chai')
sinon = require('sinon')

chai.should()

chai.use require('chai-as-promised')
chai.use require('sinon-chai')

require 'mocha-sinon'

todoist = require('../lib/todoist.js')
toggl = require '../lib/toggl.js'

projectFixture = require './fixtures/toggl-project.json'

describe 'Todoist', ->

  describe 'Event Forwarding', ->
    it 'should tell on invalid events', ->
      todoist.forward {}, null
        .should.be.rejectedWith 'no valid event_name attribute defined'

    it 'should tell on unknown events', ->
      todoist.forward { event_name: 'do:this' }, null
        .should.be.rejectedWith 'Event "do:this" cannot be handled'

  describe 'Toggl Reaction on Project Events', ->

    beforeEach ->
      toggl.api = request.defaults()
      toggl.workspaceId = 3134975

    describe 'project:added', ->

      it 'should create a project', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(null)

        createProject = sinon.stub toggl, 'createProject'
          .returns Promise.resolve(projectFixture)

        await todoist.project_added id: 123, name: 'Test Project', toggl
        
        findProjectByName.restore()
        createProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been.calledWith 'Test Project (123)'

        createProject.should.have.been.calledOnce
        createProject.should.have.been.calledWith name: 'Test Project (123)'

      it 'should not create the project if it exists already', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(projectFixture)

        createProject = sinon.stub toggl, 'createProject'

        await todoist.project_added id: 123, name: 'An awesome project', toggl

        findProjectByName.restore()
        createProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been.calledWith 'An awesome project (123)'

        createProject.should.not.have.been.called

    describe 'project:archive', ->

      it 'should archive a project', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(projectFixture.data)

        updateProject = sinon.stub toggl, 'updateProject'
          .returns Promise.resolve(projectFixture)

        await todoist.project_archived id: 123, name: 'Project C', toggl

        findProjectByName.restore()
        updateProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been.calledWith 'Project C (123)'

        updateProject.should.have.been.calledOnce
        updateProject.should.have.been.calledWithMatch
          id: 3134975
          active: false

      it 'should archive nothing if there\'s no such project', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(null)

        updateProject = sinon.stub toggl, 'updateProject'

        await todoist.project_archived
          id: 123, name: 'This Project does not exist', toggl

        findProjectByName.restore()
        updateProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been
          .calledWith 'This Project does not exist (123)'

        updateProject.should.not.have.been.called

    describe 'project:unarchived', ->

      it 'should restore a project', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(projectFixture.data)

        updateProject = sinon.stub toggl, 'updateProject'
          .returns Promise.resolve(projectFixture)

        await todoist.project_unarchived id: 123, name: 'Project C', toggl

        findProjectByName.restore()
        updateProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been.calledWith 'Project C (123)'

        updateProject.should.have.been.calledOnce
        updateProject.should.have.been.calledWithMatch
          id: 3134975
          active: true

      it 'should create a project if it does not exist', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(null)

        updateProject = sinon.stub toggl, 'updateProject'
        createProject = sinon.stub toggl, 'createProject'

        await todoist.project_unarchived
          id: 123, name: 'This Project does not exist', toggl

        findProjectByName.restore()
        updateProject.restore()
        createProject.restore()

        findProjectByName.should.have.been.calledOnce
        findProjectByName.should.have.been
          .calledWith 'This Project does not exist (123)'

        updateProject.should.not.have.been.called
        
        createProject.should.have.been.calledOnce
        createProject.should.have.been.calledWith
          name: 'This Project does not exist (123)'

    describe 'project:deleted', ->

      deleteProject = null

      beforeEach ->
        deleteProject = sinon.stub toggl, 'deleteProject'
          .returns Promise.resolve()

      afterEach ->
        deleteProject.restore()

      it 'should delete a project', ->
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(projectFixture.data)

        await todoist.project_deleted id: 123, name: 'Project C', toggl

        findProjectByName.restore()

        findProjectByName.should.have.been.calledOnce
        deleteProject.should.have.been.calledOnce

        deleteProject.should.have.been.calledWithMatch
          id: 3134975

      it 'should delete nothing if there\'s no such project', ->
        project = id: 123, name: 'This Project does not exist'
        
        findProjectByName = sinon.stub toggl, 'findProjectByName'
          .returns Promise.resolve(null)

        await todoist.project_deleted project, toggl

        findProjectByName.restore()

        findProjectByName.should.have.been.calledOnce
        deleteProject.should.not.have.been.called

        findProjectByName.should.have.been
          .calledWith 'This Project does not exist (123)'
