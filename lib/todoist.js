const log = require('./log.js')

const todoist = {

  transformed: (project) => {
    return {
      name: `${project.name} (${project.id})`
    }
  },

  project_added: (project, toggl) => {
    log.info(`Create Toggl Project "${project.name}"`)
    project = todoist.transformed(project)

    return toggl
      .findProjectByName(project.name)
      .then((existingProject) => {
        if (!existingProject) {
          return toggl.createProject(project)
        }
      })
  },

  project_archived: (project, toggl) => {
    log.info(`Archive Toggl Project "${project.name}"`)
    project = todoist.transformed(project)

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

  project_unarchived: (project, toggl) => {
    log.info(`Restore Toggl Project "${project.name}"`)
    project = todoist.transformed(project)

    return toggl
      .findProjectByName(project.name)
      .then((unarchivedProject) => {
        if (unarchivedProject) {
          return toggl.updateProject({
            id: unarchivedProject.id,
            active: true
          })
        } else {
          return toggl.createProject(project)
        }
      })
  },

  project_deleted: (project, toggl) => {
    log.info(`Delete Toggl Project "${project.name}"`)
    project = todoist.transformed(project)

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

  project_updated: (project, toggl) => {
    log.info(`Update Toggl Project to "${project.name}"`)

    return toggl
      .fetchProjects()
      .then((projects) => {
        const updatedProject = projects.find(fetchedProject =>
          fetchedProject.name.endsWith(` (${project.id})`))

        project = todoist.transformed(project)

        if (updatedProject) {
          return toggl.updateProject({
            id: updatedProject.id,
            name: project.name
          })
        } else {
          return toggl.createProject(project)
        }
      })
  },

  forward: (event, consumer) => {
    if (!event.event_name || !event.event_name.includes(':')) {
      return Promise.reject(new Error('no valid event_name attribute defined'))
    }

    const fn = event.event_name.replace(':', '_')

    if (typeof todoist[fn] === 'function') {
      log.info(`Consume Todoist Event "${event.event_name}"`)
      return todoist[fn](event.event_data, consumer)
    } else {
      return Promise.reject(new ReferenceError(
        `Event "${event.event_name}" cannot be handled`))
    }
  }
}

module.exports = todoist
