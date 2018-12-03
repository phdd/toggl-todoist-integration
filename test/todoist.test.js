process.env.NODE_ENV = 'test'
/* global describe */
/* global it */

const chai = require('chai')
const sinon = require('sinon')
const expect = chai.should()

chai.use(require('sinon-chai'))
require('mocha-sinon')

const todoist = require('../lib/todoist.js')

describe('Todoist', () => {
  describe('as Event Producer', () => {
    describe('Event Forwarding', () => {
      it('should tell on invalid events', () => {
        (() => todoist.forward({}, null))
          .should.throw(Error)
      })

      it('should tell on unknown events', () => {
        (() => todoist.forward({ event_name: 'do:this' }, null))
          .should.throw(Error)
      })
    })

    describe('Project related Events', () => {
      it('should create a named project on the consumer side', () => {
        const consumer = { onCreateProject: sinon.spy() }
        todoist.project_added({ name: 'Test Project' }, consumer)
        consumer.onCreateProject
          .should.have.been.calledWith({ name: 'Test Project' })
      })
    })
  })
})
