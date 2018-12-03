process.env.NODE_ENV = 'test'
/* global describe */
/* global beforeEach */
/* global afterEach */
/* global it */

const request = require('request')
const chai = require('chai')
const sinon = require('sinon')
const expect = chai.expect

chai.use(require('sinon-chai'))
require('mocha-sinon')

const toggl = require('../lib/toggl.js')
const workspaces = require('./fixtures/toggl-workspaces.json')

describe('Toggl', () => {
  beforeEach(() => {
    sinon.stub(request, 'get')
    sinon.stub(request, 'post')
  })

  afterEach(() => {
    request.get.restore()
    request.post.restore()
  })

  describe('Initialization', () => {
    it('should use the first available workspace', () => {
      request.get.returns(workspaces)
      toggl.init('SECRET_KEY')
      expect(request.get).to.be.calledOnce()
    })
  })

  describe('as Event Consumer', () => {
    describe('Project related Events', () => {
      it('should create a project on a "create project event"', () => {
        toggl.onCreateProject({ name: 'Test Project' })
        expect(request.post).calledOnce()
        expect(request.post).calledWith(JSON.stringify(null))
      })
    })
  })
})
