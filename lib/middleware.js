const crypto = require('crypto')
const log = require('./log')
const assert = require('assert')

const middleware = {

  hasBeenInitialized: false,

  secretsFor: (request) => {
    if (request.hasOwnProperty('webtaskContext')) {
      return request.webtaskContext.secrets
    } else {
      throw new Error('Webtask.io Secrets Missing')
    }
  },

  init: (toggl, todoist, rules) => {
    return (request, response, next) => {
      const secrets = middleware.secretsFor(request)

      if (!middleware.hasBeenInitialized) {
        const requiredSecrets = [
          'todoistApiToken',
          'todoistClientSecret',
          'togglApiToken' ]

        requiredSecrets.forEach((secret) => {
          assert(secrets.hasOwnProperty(secret), `Secret "${secret}" missing`)
        })

        Promise.all(
          [ toggl.init(secrets.togglApiToken),
            todoist.init(secrets.todoistApiToken) ])
          .then(() => rules.init(toggl, todoist))
          .then(() => next())

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
