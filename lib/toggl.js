const request = require('request')

const toggl = {

  workspaceId: -1,

  init: (apiKey) => {
    request.defaults({
      json: true,
      baseUrl: 'https://www.toggl.com/api/v8',
      headers: {
        Authorization: `${apiKey}:api_token`
      }
    })

    toggl.workspaceId = request.get({
      uri: '/workspaces'
    })[0].id
  },

  onCreateProject: (project) => {
    project.wid = toggl.workspaceId

    request.post({
      uri: '/projects',
      body: project
    })
  }

}

module.exports = toggl
