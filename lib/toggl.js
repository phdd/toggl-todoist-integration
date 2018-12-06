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
    return toggl
      .findProjectByName(project.name)
      .then((existingProject) => {
        if (!existingProject) {
          return toggl.createProject(project)
        }
      })
  },

  onArchiveProject: (project) => {
    return toggl
      .findProjectByName(project.name)
      .then((archivedProject) => {
        if (archivedProject) {
          return toggl.updateProject({
            id: archivedProject.id,
            active: false
          })
        }
      })
  },

  onDeleteProject: (project) => {
    return toggl
      .findProjectByName(project.name)
      .then((deletedProject) => {
        if (deletedProject) {
          return toggl.deleteProject({
            id: deletedProject.id
          })
        }
      })
  },

  createProject: (project) => {
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

  findProjectByName: (name) => {
    return new Promise((resolve, reject) => {
      toggl
        .fetchProjects()
        .then((projects) => {
          resolve(projects
            .find(fetchedProject => fetchedProject.name === name))
        })
    })
  },

  deleteProject: (project) => {
    return new Promise((resolve, reject) => {
      toggl.api.del({
        uri: `/projects/${project.id}`
      }, (error, response, body) => {
        if (error) {
          reject(new Error(`Toggl Project Deletion failed: ${error}`))
        } else {
          resolve(body)
        }
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
