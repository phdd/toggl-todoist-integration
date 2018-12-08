'use strict'

process.env.NODE_ENV = 'test'

request = require 'request'
chai = require('chai')
sinon = require('sinon')

chai.should()

chai.use require('chai-as-promised')
chai.use require('sinon-chai')

require 'mocha-sinon'

todoist = require '../lib/todoist'

describe 'Todoist', ->

  beforeEach ->
    sinon.stub request, 'get'
    sinon.stub request, 'post'
    sinon.stub request, 'put'
    sinon.stub request, 'del'
    sinon.spy request, 'defaults'

  afterEach ->
    request.get.restore()
    request.post.restore()
    request.put.restore()
    request.del.restore()
    request.defaults.restore()

  describe 'Initialization', ->

    it 'should setup the request defaults', ->
      await todoist.init 'TODOIST_API_KEY'

      request.defaults.should.have.been.calledOnce
      request.defaults.should.have.been.calledWith
        json: true
        baseUrl: 'https://beta.todoist.com/API/v8'
        headers:
          Authorization: 'Bearer TODOIST_API_KEY'

  describe 'API Methods', ->

    xit 'should do something', ->
