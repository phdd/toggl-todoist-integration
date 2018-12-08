const log = require('./log')

const rules = {

  toggl: null,
  todoist: null,

  init: (toggl, todoist) => {
    rules.toggl = toggl
    rules.todoist = todoist

    return Promise.resolve()
  },

  togglTransformed: (project) => {
    return {
      name: `${project.name} (${project.id})`
    }
  },

  projectCreationRulesFor: (todoistProject, togglProject) => {
    return rules.toggl
      .createProject(togglProject)
      .then(project => (togglProject = project))
      .then(rules.toggl.buildProjectReportLinkFor)
      .then(reportLink => ({
        content: `* [:alarm_clock: Timesheet](${reportLink})`,
        project_id: todoistProject.id
      }))
      .then(rules.todoist.createTask)
      .then(todoistTask => ({
        togglProject: togglProject,
        todoistTask: todoistTask
      }))
  },

  project_added: (todoistProject) => {
    log.info(`Create Toggl Project "${todoistProject.name}"`)
    const togglProject = rules.togglTransformed(todoistProject)

    return rules.toggl
      .findProjectByName(togglProject.name)
      .then((existingProject) => {
        if (!existingProject) {
          return rules.projectCreationRulesFor(todoistProject, togglProject)
        }
      })
  },

  project_archived: (project) => {
    log.info(`Archive Toggl Project "${project.name}"`)
    const togglProject = rules.togglTransformed(project)

    return rules.toggl
      .findProjectByName(togglProject.name)
      .then((archivedProject) => {
        if (archivedProject) {
          return rules.toggl.updateProject({
            id: archivedProject.id,
            active: false
          })
        }
      })
  },

  project_unarchived: (todoistProject) => {
    log.info(`Restore Toggl Project "${todoistProject.name}"`)
    const togglProject = rules.togglTransformed(todoistProject)

    return rules.toggl
      .findProjectByName(togglProject.name)
      .then((unarchivedProject) => {
        if (unarchivedProject) {
          return rules.toggl.updateProject({
            id: unarchivedProject.id,
            active: true
          })
        } else {
          return rules.projectCreationRulesFor(todoistProject, togglProject)
        }
      })
  },

  project_deleted: (project) => {
    log.info(`Delete Toggl Project "${project.name}"`)
    const togglProject = rules.togglTransformed(project)

    return rules.toggl
      .findProjectByName(togglProject.name)
      .then((deletedProject) => {
        if (deletedProject) {
          return rules.toggl.deleteProject({
            id: deletedProject.id
          })
        }
      })
  },

  project_updated: (todoistProject) => {
    log.info(`Update Toggl Project to "${todoistProject.name}"`)

    return rules.toggl
      .fetchProjects()
      .then((projects) => {
        const updatedProject = projects.find(fetchedProject =>
          fetchedProject.name.endsWith(` (${todoistProject.id})`))

        const togglProject = rules.togglTransformed(todoistProject)

        if (updatedProject) {
          return rules.toggl.updateProject({
            id: updatedProject.id,
            name: togglProject.name
          })
        } else {
          return rules.projectCreationRulesFor(todoistProject, togglProject)
        }
      })
  },

  forward: (event) => {
    if (!event.event_name || !event.event_name.includes(':')) {
      return Promise.reject(new Error('no valid event_name attribute defined'))
    }

    const fn = event.event_name.replace(':', '_')

    if (typeof rules[fn] === 'function') {
      log.info(`Consume Todoist Event "${event.event_name}"`)
      return rules[fn](event.event_data)
    } else {
      return Promise.reject(new ReferenceError(
        `Event "${event.event_name}" cannot be handled`))
    }
  }
}

module.exports = rules
