const request = require('request')

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
    return new Promise((resolve, reject) => {
      todoist.api.post({
        uri: '/tasks',
        body: task
      }, (error, response, body) => {
        if (error) {
          reject(new Error(`Todoist Task Creation failed: ${error}`))
        } else {
          resolve(body)
        }
      })
    })
  }

}

module.exports = todoist
