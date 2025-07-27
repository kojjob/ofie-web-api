import { ErrorHandler } from '../utils/error_handler'

// Mixin to add error handling capabilities to Stimulus controllers
export const ErrorHandlingMixin = (superclass) => class extends superclass {
  // Wrap async method with error handling
  async handleAsync(operation, options = {}) {
    const defaultOptions = {
      showNotification: true,
      onError: (error) => this.handleError(error),
      onFinally: () => this.handleFinally(),
      ...options
    }

    return ErrorHandler.handleAsync(operation, defaultOptions)
  }

  // Default error handler - can be overridden in controllers
  handleError(error) {
    console.error(`Error in ${this.identifier} controller:`, error)
    
    // Update UI to show error state if method exists
    if (typeof this.showErrorState === 'function') {
      this.showErrorState(error)
    }
  }

  // Default finally handler - can be overridden in controllers
  handleFinally() {
    // Hide loading state if method exists
    if (typeof this.hideLoadingState === 'function') {
      this.hideLoadingState()
    }
  }

  // Convenience method for fetch with error handling
  async fetchWithErrorHandling(url, options = {}) {
    return ErrorHandler.fetch(url, options)
  }

  // Show loading state with optional message
  showLoadingState(message = 'Loading...') {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
      if (this.hasLoadingMessageTarget) {
        this.loadingMessageTarget.textContent = message
      }
    }
  }

  // Hide loading state
  hideLoadingState() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
  }

  // Show error state with message
  showErrorState(error) {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove('hidden')
      if (this.hasErrorMessageTarget) {
        this.errorMessageTarget.textContent = error.message || 'An error occurred'
      }
    }
  }

  // Hide error state
  hideErrorState() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add('hidden')
    }
  }

  // Disable form/buttons during async operation
  disableInteraction() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
    
    // Disable all interactive elements
    this.element.querySelectorAll('button, input, select, textarea').forEach(el => {
      el.disabled = true
    })
  }

  // Enable form/buttons after async operation
  enableInteraction() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    }
    
    // Enable all interactive elements
    this.element.querySelectorAll('button, input, select, textarea').forEach(el => {
      el.disabled = false
    })
  }

  // Validate required targets exist
  validateRequiredTargets(targets) {
    const missing = targets.filter(target => !this[`has${target.charAt(0).toUpperCase() + target.slice(1)}Target`])
    
    if (missing.length > 0) {
      throw new Error(`Missing required targets in ${this.identifier}: ${missing.join(', ')}`)
    }
  }

  // Handle form validation errors
  displayValidationErrors(errors) {
    // Clear previous errors
    this.clearValidationErrors()
    
    Object.entries(errors).forEach(([field, messages]) => {
      const fieldElement = this.element.querySelector(`[name="${field}"]`)
      if (fieldElement) {
        // Add error class to field
        fieldElement.classList.add('border-red-500')
        
        // Show error message
        const errorId = `${field}-error`
        let errorElement = this.element.querySelector(`#${errorId}`)
        
        if (!errorElement) {
          errorElement = document.createElement('p')
          errorElement.id = errorId
          errorElement.className = 'mt-1 text-sm text-red-600'
          fieldElement.parentElement.appendChild(errorElement)
        }
        
        errorElement.textContent = Array.isArray(messages) ? messages.join(', ') : messages
      }
    })
  }

  // Clear validation errors
  clearValidationErrors() {
    this.element.querySelectorAll('.border-red-500').forEach(el => {
      el.classList.remove('border-red-500')
    })
    
    this.element.querySelectorAll('[id$="-error"]').forEach(el => {
      el.remove()
    })
  }

  // Debounce function for input handlers
  debounce(func, wait) {
    let timeout
    return (...args) => {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, args), wait)
    }
  }

  // Throttle function for scroll/resize handlers
  throttle(func, limit) {
    let inThrottle
    return (...args) => {
      if (!inThrottle) {
        func.apply(this, args)
        inThrottle = true
        setTimeout(() => inThrottle = false, limit)
      }
    }
  }
}