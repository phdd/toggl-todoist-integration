const middleware = {

  hasBeenInitialized: false,

  secretsFor: (request) => {
    if (process.env.NODE_ENV !== 'test') {
      return request.webtaskContext.secrets
    } else {
      return {
        togglApiKey: 'SECRET_KEY',
        todoistClientSecret: 'TODOIST_CLIENT_SECRET'
      }
    }
  },

  init: (toggl) => {
    return (request, response, next) => {
      if (!middleware.hasBeenInitialized) {
        toggl
          .init(middleware.secretsFor(request).togglApiKey)
          .then(next)

        middleware.hasBeenInitialized = true
      } else {
        next()
      }
    }
  },

  // TODO: write middleware for X-Todoist-Hmac-SHA256
  todoistRequestValidation: (request, response, next) => {
    next()
  },

  // TODO: write middleware for X-Todoist-Delivery-ID buffer
  // see https://developer.todoist.com/sync/v7/?shell#request-format
  // see https://stackoverflow.com/a/4852052
  todoistDeliveryFilter: (request, response, next) => {
    next()
  }

}

module.exports = middleware
