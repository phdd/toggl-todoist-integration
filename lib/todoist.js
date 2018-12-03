const assert = require('assert')

const todoist = {

  project_added: (data, consumer) => {
    consumer.onCreateProject({
      'name': data.name
    })
  },

  forward: (event, consumer) => {
    assert(event.event_name && event.event_name.includes(':'),
      'no valid event_name attribute defined')

    const fn = event.event_name.replace(':', '_')

    if (typeof this[fn] === 'function') {
      this[fn](event.event_data, consumer)
    } else {
      throw new ReferenceError(`Event "${event.event_name}" cannot be handled`)
    }
  }
}

module.exports = todoist
