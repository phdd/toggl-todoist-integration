const log = {
  combine: (message, details) => {
    if (details) {
      return `${message}: ${JSON.stringify(details)}`
    } else {
      return message
    }
  },

  toConsole: (type, message, details) => {
    console[type](log.combine(message, details))
  },

  info: (message, details) => {
    log.toConsole('log', message, details)
  },

  warn: (message, details) => {
    log.toConsole('warn', message, details)
  },

  error: (message, details) => {
    log.toConsole('error', message, details)
  }
}

module.exports = log
