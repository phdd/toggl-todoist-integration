sandbox = require('sinon').createSandbox()
nock = require 'nock'
chai = require 'chai'
request = require 'supertest'

middleware = null

utils =

  todoist: null
  toggl: null
  app: null

  before: ->
    chai.should()
    nock.disableNetConnect()
    nock.enableNetConnect /127\.0\.0\.1/

  beforeEach: ->
    require('../../lib/log').toConsole = sandbox.stub()

    middleware = require '../../lib/middleware'

    todoistRequestValidation = sandbox
      .stub middleware, 'todoistRequestValidation'
        .callsFake (request, response, next) -> next()

    secretsFor = sandbox
      .stub middleware, 'secretsFor'
        .returns
          todoistApiToken: 'TODOIST_API_TOKEN'
          togglApiToken: 'TOGGL_API_TOKEN'
          todoistClientSecret: 'TODOIST_CLIENT_SECRET'

    utils.toggl =
      project:
        creation:
          expectation: ->
          response: id: 12
          request:
            nock /toggl\.com/
              .post /projects/, (project) ->
                utils.toggl.project.creation.expectation project
              .reply 201, (path, container) ->
                container.project.id = utils.toggl.project.creation.response.id
                return data: container.project

      workspace:
        list:
          response: [ id: 3092940 ]
          request:
            nock /toggl\.com/
              .get /workspaces/
              .reply 200, -> utils.toggl.workspace.list.response

    utils.todoist =
      comment:
        creation:
          expectation: ->
          response: id: 17
          request:
            nock /todoist\.com/
              .post /comments/, (comment) ->
                utils.todoist.comment.creation.expectation comment
              .reply 201, (path, comment) ->
                comment.id = utils.todoist.comment.creation.response.id
                return comment

      project:
        response: id: 5468, name: 'Fancy Project'
        request:
          nock /todoist\.com/
            .get /projects\/[0-9]+/
            .reply 200, -> utils.todoist.project.response

        comments:
          response: [ project_id: 123, content: 'A Comment' ]
          request:
            nock /todoist\.com/
              .get /comments\?project_id=/
              .reply 200, -> utils.todoist.project.comments.response

    utils.app = request(require('../../app')).post('/todoist-event')

    return
      app: utils.app
      todoist: utils.todoist
      toggl: utils.toggl
      expect: chai.expect

  afterEach: ->
    nock.cleanAll()
    sandbox.restore()
    middleware.hasBeenInitialized = false

module.exports = utils
