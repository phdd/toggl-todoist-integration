const todoist = require('./lib/todoist.js')
const toggl = require('./lib/toggl.js')

module.exports = (context, respond) => {
  todoist.init(context.secrets.todoistApiKey)
  toggl.init(context.secrets.togglApiKey)

  if (context.headers['Todoist-Webhooks']) {
    respond(null, todoist.forward(context.body, toggl))
  } else {
    throw new Error('invalid request')
  }
}
