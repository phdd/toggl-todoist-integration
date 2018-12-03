process.env.NODE_ENV = 'test'
/* global describe */
/* global it */

const chai = require('chai')
const sinon = require('sinon')
const expect = chai.expect

chai.use(require('sinon-chai'))
require('mocha-sinon')

const todoist = require('../lib/todoist.js')

describe('Todoist', () => {
  describe('as Event Producer', () => {
    describe('Event Forwarding', () => {
      it('should tell on invalid events', () => {
        expect(() => todoist.forward({}, null))
          .to.throw('no valid event_name attribute defined')
      })

      it('should tell on unknown events', () => {
        expect(() => todoist.forward({ event_name: 'do:this' }, null))
          .to.throw('Event "do:this" cannot be handled')
      })
    })

    describe('Project related Events', () => {
      it('should create a named project on the consumer side', () => {
        const consumer = { onCreateProject: sinon.spy() }
        todoist.project_added({ name: 'Test Project' }, consumer)
        expect(consumer.onCreateProject)
          .to.have.been.calledWith({ name: 'Test Project' })
      })
    })
  })
})
