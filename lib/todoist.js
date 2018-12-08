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
  }

}

module.exports = todoist
