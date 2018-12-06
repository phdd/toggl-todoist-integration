const request = require('request')

const toggl = {

  workspaceId: -1,
  api: null,

  init: (apiKey) => {
    const credentials = Buffer.from(`${apiKey}:api_token`).toString('base64')

    toggl.api = request.defaults({
      json: true,
      baseUrl: 'https://www.toggl.com/api/v8',
      headers: {
        Authorization: `Basic ${credentials}`
      }
    })

    return new Promise((resolve, reject) => {
      toggl.api.get('/workspaces', (error, response, body) => {
        if (error) {
          reject(new Error(`Getting Toggl Workspaces failed: ${error}`))
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
        body: {
          project: project
        }
      }, (error, response, body) => {
        if (error) {
          reject(new Error(`Toggl Project Creation failed: ${error}`))
        } else {
          resolve(body)
        }
      })
    })
  },

  onArchiveProject: (projectName) => {
    return toggl
      .fetchProjects()
      .then((projects) => {
        return toggl.updateProject({
          id: projects.find(project => project.name === projectName).id,
          active: false
        })
      })
  },

  updateProject: (project) => {
    return new Promise((resolve, reject) => {
      toggl.api.put({
        uri: `/projects/${project.id}`,
        body: { project: project }
      }, (error, response, body) => {
        if (error) {
          reject(new Error(`Toggl Project Update failed: ${error}`))
        } else {
          resolve(body)
        }
      })
    })
  },

  fetchProjects: () => {
    return new Promise((resolve, reject) => {
      const projects = `/workspaces/${toggl.workspaceId}/projects`

      toggl.api.get(projects, (error, response, body) => {
        if (error) {
          reject(new Error(`Getting Toggl Projects failed: ${error}`))
        } else {
          resolve(body)
        }
      })
    })
  }

}

module.exports = toggl
