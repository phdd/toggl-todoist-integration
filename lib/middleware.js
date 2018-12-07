const crypto = require('crypto')
const log = require('./log')

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

  todoistRequestValidation: (request, response, next) => {
    const encryptionKey = middleware.secretsFor(request).todoistClientSecret
    const actualSignatureString = request.get('X-Todoist-Hmac-SHA256')

    if (actualSignatureString) {
      const expectedSignature = crypto
        .createHmac('SHA256', encryptionKey)
        .update(request.rawBody)
        .digest()

      const actualSignature = Buffer.from(actualSignatureString, 'base64')

      if (expectedSignature.length === actualSignature.length &&
        crypto.timingSafeEqual(expectedSignature, actualSignature)
      ) {
        return next()
      }
    }

    log.warn('Invalid Signature')
    return response.status(403)
  },

  // TODO: write middleware for X-Todoist-Delivery-ID buffer
  // see https://developer.todoist.com/sync/v7/?shell#request-format
  // see https://stackoverflow.com/a/4852052
  todoistDeliveryFilter: (request, response, next) => {
    next()
  }

}

module.exports = middleware
