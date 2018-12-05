const app = require('express')()
const bodyParser = require('body-parser')

const todoist = require('./lib/todoist.js')
const toggl = require('./lib/toggl.js')
const log = require('./lib/log.js')

const secretsFor = (request) => {
  if (process.env.NODE_ENV !== 'test') {
    return request.webtaskContext.secrets
  } else {
    return {
      togglApiKey: 'SECRET_KEY'
    }
  }
}

const hasBeenInitialized = false

app.use((request, response, next) => {
  if (!hasBeenInitialized) {
    toggl
      .init(secretsFor(request).togglApiKey)
      .then(next)
  }
})

app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

app.post('/todoist-event', (request, response) => {
  todoist
    .forward(request.body, toggl)
    .then((togglProject) => {
      response.status(200).send(togglProject)
    })
    .catch((error) => {
      if (error instanceof ReferenceError) {
        log.warn('Unhandled Event', { name: request.body.event_name })
        response.status(200).send({
          warn: error.message
        })
      } else {
        log.warn('Unknown Error',
          { message: error.message, body: request.body })
        response.status(400).send({
          error: error.message
        })
      }
    })
})

module.exports = app
