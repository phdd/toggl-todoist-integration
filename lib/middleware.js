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
    let expectedSignature = null
    const forbidden = () => {
      log.warn('Invalid Signature')
      response.status(403)
    }

    if (!actualSignatureString) {
      return forbidden()
    }

    try {
      expectedSignature = crypto
        .createHmac('SHA256', encryptionKey)
        .update(request.body)
        .digest()
    } catch (error) {
      return forbidden()
    }

    const actualSignature = Buffer.from(actualSignatureString, 'base64')

    try {
      if (crypto.timingSafeEqual(expectedSignature, actualSignature)) {
        return next()
      } else {
        return forbidden()
      }
    } catch (error) {
      return forbidden()
    }
  },

  // TODO: write middleware for X-Todoist-Delivery-ID buffer
  // see https://developer.todoist.com/sync/v7/?shell#request-format
  // see https://stackoverflow.com/a/4852052
  todoistDeliveryFilter: (request, response, next) => {
    next()
  }

}

module.exports = middleware
