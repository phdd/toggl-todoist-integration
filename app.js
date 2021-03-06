const app = require('express')()
const bodyParser = require('body-parser')

const log = require('./lib/log')
const middleware = require('./lib/middleware')
const rules = require('./lib/rules')
const toggl = require('./lib/toggl')
const todoist = require('./lib/todoist')

const rawBodySaver = (request, response, buffer) => {
  request.rawBody = buffer.toString()
}

app.use(bodyParser.json({ verify: rawBodySaver }))
app.use(middleware.todoistRequestValidation)
app.use(middleware.todoistDeliveryFilter)
app.use(middleware.init(toggl, todoist, rules))

app.post('/todoist-event', (request, response) => {
  rules
    .forward(request.body)
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
        console.error('Unknown Error', error)
      }
    })
})

module.exports = app
