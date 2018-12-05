const todoist = {

  project_added: (data, consumer) => {
    console.log(`project:added => create Toggl project named ${data.name}`)
    return consumer.onCreateProject({
      'name': data.name
    })
  },

  forward: (event, consumer) => {
    if (!event.event_name || !event.event_name.includes(':')) {
      return Promise.reject(new Error('no valid event_name attribute defined'))
    }

    const fn = event.event_name.replace(':', '_')

    if (typeof todoist[fn] === 'function') {
      return todoist[fn](event.event_data, consumer)
    } else {
      return Promise.reject(new ReferenceError(
        `Event "${event.event_name}" cannot be handled`))
    }
  }
}

module.exports = todoist
