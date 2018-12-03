process.env.NODE_ENV = 'test'
/* global describe */
/* global beforeEach */
/* global afterEach */
/* global it */

const request = require('request')
const chai = require('chai')
const sinon = require('sinon')
const expect = chai.should()

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
      request.get.should.have.been.calledWith(
        'https://www.toggl.com/api/v8/workspaces',
        { Authorization: 'SECRET_KEY:api_token' })
    })
  })

  describe('as Event Consumer', () => {
    describe('Project related Events', () => {
      it('should create a project on a "create project event"', () => {
        toggl.onCreateProject({ name: 'Test Project' })
        request.post.should.have.been.calledOnce()
        request.post.should.have.been.calledWith(JSON.stringify(null))
      })
    })
  })
})
