const log = require('./log.js')

const todoist = {

  project_added: (data, consumer) => {
    log.info('Create Toggl Project', { name: data.name })
    return consumer.onCreateProject({
      'name': data.name
    })
  },

  project_archived: (data, consumer) => {
    log.info('Archive Toggl Project', { name: data.name })
    return consumer.onArchiveProject({
      'name': data.name
    })
  },

  forward: (event, consumer) => {
    if (!event.event_name || !event.event_name.includes(':')) {
      return Promise.reject(new Error('no valid event_name attribute defined'))
    }

    const fn = event.event_name.replace(':', '_')

    if (typeof todoist[fn] === 'function') {
      log.info('Consume Todoist Event', { event: event.event_name })
      return todoist[fn](event.event_data, consumer)
    } else {
      return Promise.reject(new ReferenceError(
        `Event "${event.event_name}" cannot be handled`))
    }
  }
}

module.exports = todoist
