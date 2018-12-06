'use strict'

process.env.NODE_ENV = 'test'

chai = require('chai')
sinon = require('sinon')

chai.should()

chai.use require('chai-as-promised')
chai.use require('sinon-chai')

require 'mocha-sinon'
todoist = require('../lib/todoist.js')

describe 'Todoist', ->

  describe 'Event Forwarding', ->
    it 'should tell on invalid events', ->
      todoist.forward {}, null
        .should.be.rejectedWith 'no valid event_name attribute defined'

    it 'should tell on unknown events', ->
      todoist.forward { event_name: 'do:this' }, null
        .should.be.rejectedWith 'Event "do:this" cannot be handled'

  describe 'Project related Event Production', ->

    it 'should create a named project on the consumer side', ->
      consumer = onCreateProject: sinon.spy()

      todoist.project_added { name: 'Test Project' }, consumer

      consumer.onCreateProject
        .should.have.been.calledOnceWith name: 'Test Project'

    it 'should archive projects on the consumer side', ->
      consumer = onArchiveProject: sinon.spy()

      todoist.project_archived { name: 'Test Project' }, consumer

      consumer.onArchiveProject
        .should.have.been.calledOnceWith name: 'Test Project'

    it 'should delete projects on the consumer side', ->
      consumer = onDeleteProject: sinon.spy()

      todoist.project_deleted { name: 'Test Project' }, consumer

      consumer.onDeleteProject
        .should.have.been.calledOnceWith name: 'Test Project'
