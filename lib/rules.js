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
      name: `${project.name}`
    }
  },

  projectCreationRulesFor: (todoistProject, togglProject) => {
    log.info(`Create Todoist Project comment linking Toggl report`)

    return rules.toggl
      .createProject(togglProject)
      .then(project => (togglProject = project))
      .then(rules.toggl.buildProjectReportLinkFor)
      .then(reportLink => ({
        content: `:alarm_clock: [Toggl Timesheet](${reportLink})`,
        project_id: todoistProject.id
      }))
      .then(rules.todoist.createComment)
      .then(todoistComment => ({
        togglProject: togglProject,
        todoistComment: todoistComment
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

    return rules.todoist
      .fetchProjectComments(todoistProject.id)
      .then(comments => {
        const timesheetLink = /\[Toggl Timesheet\]\((.+)\)/
        const comment = comments
          .find(fetchedComment => timesheetLink.test(fetchedComment.content))

        if (comment) {
          const link = comment.content.match(timesheetLink)[1]
          togglProject.id = rules.toggl.projectIdFrom(link)
          return rules.toggl.updateProject({
            id: togglProject.id,
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
    const togglProject = rules.togglTransformed(todoistProject)

    return rules.todoist
      .fetchProjectComments(todoistProject.id)
      .then(comments => {
        const timesheetLink = /\[Toggl Timesheet\]\((.+)\)/
        const comment = comments
          .find(fetchedComment => timesheetLink.test(fetchedComment.content))

        if (comment) {
          const link = comment.content.match(timesheetLink)[1]
          togglProject.id = rules.toggl.projectIdFrom(link)
          return rules.toggl.updateProject(togglProject)
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
