// Centralized error handling for async operations
export class ErrorHandler {
  static async handleAsync(operation, options = {}) {
    const {
      onError = null,
      onFinally = null,
      retries = 0,
      retryDelay = 1000,
      showNotification = true,
      customErrorMessage = null
    } = options

    let lastError = null
    let attempt = 0

    while (attempt <= retries) {
      try {
        const result = await operation()
        return { success: true, data: result, error: null }
      } catch (error) {
        lastError = error
        attempt++

        if (attempt <= retries) {
          await this.delay(retryDelay * attempt)
          continue
        }

        // Log error
        this.logError(error, { attempt, retries })

        // Handle specific error types
        const errorInfo = this.parseError(error)
        
        // Show notification if enabled
        if (showNotification) {
          this.showErrorNotification(customErrorMessage || errorInfo.message)
        }

        // Call custom error handler if provided
        if (onError) {
          onError(errorInfo)
        }

        return { success: false, data: null, error: errorInfo }
      } finally {
        if (onFinally && attempt > retries) {
          onFinally()
        }
      }
    }
  }

  static parseError(error) {
    // Network errors
    if (error instanceof TypeError && error.message.includes('fetch')) {
      return {
        type: 'network',
        message: 'Network connection error. Please check your internet connection.',
        details: error.message
      }
    }

    // HTTP errors
    if (error.status) {
      return this.parseHttpError(error)
    }

    // Validation errors
    if (error.errors) {
      return {
        type: 'validation',
        message: 'Validation failed',
        details: error.errors,
        fields: this.parseValidationErrors(error.errors)
      }
    }

    // Generic errors
    return {
      type: 'generic',
      message: error.message || 'An unexpected error occurred',
      details: error
    }
  }

  static parseHttpError(error) {
    const statusMessages = {
      400: 'Bad request. Please check your input.',
      401: 'You need to be logged in to perform this action.',
      403: 'You do not have permission to perform this action.',
      404: 'The requested resource was not found.',
      422: 'The data you submitted is invalid.',
      429: 'Too many requests. Please slow down.',
      500: 'Server error. Please try again later.',
      502: 'Server is temporarily unavailable.',
      503: 'Service is temporarily unavailable.'
    }

    return {
      type: 'http',
      status: error.status,
      message: statusMessages[error.status] || `HTTP Error ${error.status}`,
      details: error.statusText || error.message
    }
  }

  static parseValidationErrors(errors) {
    if (Array.isArray(errors)) {
      return errors.reduce((acc, error) => {
        acc.general = acc.general || []
        acc.general.push(error)
        return acc
      }, {})
    }

    if (typeof errors === 'object') {
      return errors
    }

    return { general: [errors.toString()] }
  }

  static showErrorNotification(message) {
    if (window.NotificationSystem) {
      window.NotificationSystem.error(message)
    } else {
      console.error('Notification system not available:', message)
    }
  }

  static logError(error, context = {}) {
    const errorInfo = {
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
      url: window.location.href,
      userAgent: navigator.userAgent,
      ...context
    }

    // Log to console in development
    if (process.env.NODE_ENV !== 'production') {
      console.error('Error caught:', errorInfo)
    }

    // Send to error tracking service in production
    if (window.Sentry && process.env.NODE_ENV === 'production') {
      window.Sentry.captureException(error, {
        extra: context
      })
    }
  }

  static delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // Fetch wrapper with error handling
  static async fetch(url, options = {}) {
    return this.handleAsync(async () => {
      const response = await fetch(url, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
          ...options.headers
        }
      })

      if (!response.ok) {
        const error = new Error(`HTTP ${response.status}`)
        error.status = response.status
        error.statusText = response.statusText
        
        try {
          const data = await response.json()
          error.details = data
          error.message = data.error || data.message || error.message
        } catch (e) {
          // Response is not JSON
        }
        
        throw error
      }

      const contentType = response.headers.get('content-type')
      if (contentType && contentType.includes('application/json')) {
        return response.json()
      }
      
      return response.text()
    }, options)
  }
};
