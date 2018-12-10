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

  createComment: (comment) => {
    return todoist.api
      .post({
        uri: '/comments',
        body: comment
      })
  },

  fetchProjectComments: (projectId) => {
    return todoist.api.get(`/comments?project_id=${projectId}`)
  }

}

module.exports = todoist
