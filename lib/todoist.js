const request = require('request-promise-native')

const todoist = {

  api: null,

  init: (apiKey) => {
    todoist.api = request.defaults({
      json: true,
      baseUrl: 'https://beta.todoist.com/API/v8',
      headers: {
        Authorization: `Bearer ${apiKey}`
      }
    })

    return Promise.resolve()
  },

  createTask: (task) => {
    return todoist.api
      .post({
        uri: '/tasks',
        body: task
      })
  }

}

module.exports = todoist
