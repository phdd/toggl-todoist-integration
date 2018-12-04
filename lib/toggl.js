const request = require('request')

const togglUrl = 'https://www.toggl.com/api/v8'

const optionsWith = (options) => {
  return Object.assign({}, toggl.requestOptions, options)
}

const toggl = {

  workspaceId: -1,

  requestOptions: {
    Authorization: null
  },

  init: (apiKey) => {
    toggl.requestOptions.Authorization = `${apiKey}:api_token`
    toggl.workspaceId = request
      .get(optionsWith({ url: `${togglUrl}/workspaces` }))[0].id
  },

  onCreateProject: (project) => {
    request.post(optionsWith({
      url: `${togglUrl}/projects`,
      body: project
    }))
  }

}

module.exports = toggl
