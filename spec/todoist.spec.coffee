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

      #(-> todoist.forward {}, null )
      #  .should.throw Error

    it 'should tell on unknown events', ->
      todoist.forward { event_name: 'do:this' }, null
        .should.be.rejectedWith 'Event "do:this" cannot be handled'

  describe 'produces Project related Events', ->

    it 'should create a named project on the consumer side', ->
      consumer = onCreateProject: sinon.spy()

      todoist.project_added { name: 'Test Project' }, consumer

      consumer.onCreateProject
        .should.have.been.calledWith name: 'Test Project'
