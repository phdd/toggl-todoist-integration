const request = require('request-promise-native')

const frontendBase = 'https://www.toggl.com/app/'

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

    return toggl.api
      .get('/workspaces')
      .then(workspaces => {
        toggl.workspaceId = workspaces[0].id
      })
  },

  buildProjectReportLinkFor: (project) => {
    return `${frontendBase}reports/summary/` +
           `${project.wid}/period/thisWeek/projects/${project.id}`
  },

  createProject: (project) => {
    project.wid = toggl.workspaceId

    return toggl.api
      .post({
        uri: '/projects',
        body: { project: project }
      })
      .then(body => body.data)
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
    return toggl.api
      .del({
        uri: `/projects/${project.id}`
      })
  },

  updateProject: (project) => {
    return toggl.api
      .put({
        uri: `/projects/${project.id}`,
        body: { project: project }
      })
      .then(body => body.data)
  },

  fetchProjects: () => {
    return toggl.api
      .get(`/workspaces/${toggl.workspaceId}/projects?active=both`)
  }

}

module.exports = toggl
