const request = require('request')

const togglUrl = 'https://www.toggl.com/api/v8'

let workspaceId = -1

const options = {
  Authorization: null
}

const toggl = {

  init: (apiKey) => {
    options.Authorization = `${apiKey}:api_token`
    workspaceId = request.get(`${togglUrl}/workspaces`, options)[0]
  },

  onCreateProject: (project) => {
    request.post(`${togglUrl}/projects`, options)
  }
}

module.exports = toggl
