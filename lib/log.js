let isEnabled = true

const combine = (message, details) => {
  return `${message}: ${JSON.stringify(details)}`
}

const toConsole = (type, message, details) => {
  if (isEnabled) {
    console[type](combine(message, details))
  }
}

const log = {
  disable: () => {
    isEnabled = false
  },

  info: (message, details) => {
    toConsole('log', message, details)
  },

  warn: (message, details) => {
    toConsole('warn', message, details)
  },

  error: (message, details) => {
    toConsole('error', message, details)
  }
}

if (process.env.NODE_ENV === 'test') {
  log.disable()
}

module.exports = log
