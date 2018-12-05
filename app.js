const Express = require('express')
const bodyParser = require('body-parser')

const todoist = require('./lib/todoist.js')
const toggl = require('./lib/toggl.js')

const app = new Express()

const secretsFor = (request) => {
  if (process.env.NODE_ENV === 'webtask') {
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
      response.status(500).send({
        error: error.message
      })
    })
})

module.exports = app
