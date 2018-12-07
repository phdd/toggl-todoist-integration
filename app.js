const app = require('express')()
const bodyParser = require('body-parser')

const log = require('./lib/log.js')
const middleware = require('./lib/middleware.js')
const todoist = require('./lib/todoist.js')
const toggl = require('./lib/toggl.js')

const rawBodySaver = (request, response, buffer) => {
  request.rawBody = buffer.toString()
}

app.use(bodyParser.json({ verify: rawBodySaver }))
app.use(middleware.todoistRequestValidation)
app.use(middleware.todoistDeliveryFilter)
app.use(middleware.init(toggl))

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
