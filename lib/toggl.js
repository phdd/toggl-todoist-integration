const request = require('request')

const toggl = {

  workspaceId: -1,
  api: null,

  init: (apiKey) => {
    toggl.api = request.defaults({
      json: true,
      baseUrl: 'https://www.toggl.com/api/v8',
      headers: {
        Authorization: `${apiKey}:api_token`
      }
    })

    return new Promise((resolve, reject) => {
      toggl.api.get('/workspaces', (error, response, body) => {
        if (error) {
          reject(new Error('Getting Toggl Workspaces failed'))
        } else {
          toggl.workspaceId = body[0].id
          resolve()
        }
      })
    })
  },

  onCreateProject: (project) => {
    project.wid = toggl.workspaceId

    return new Promise((resolve, reject) => {
      toggl.api.post({
        uri: '/projects',
        body: project
      }, (error, response, body) => {
        if (error) {
          reject(new Error('Toggl Project Creation failed'))
        } else {
          resolve(body)
        }
      })
    })
  }

}

module.exports = toggl
