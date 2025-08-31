import { Controller } from "@hotwired/stimulus"

// Unified notification system controller
export default class extends Controller {
  static targets = ["container"]
  static values = {
    position: { type: String, default: "top-right" },
    maxNotifications: { type: Number, default: 5 },
    defaultDuration: { type: Number, default: 5000 }
  }

  connect() {
    this.notifications = new Map()
    this.setupGlobalAPI()
    this.setupPositioning()
  }

  disconnect() {
    this.removeGlobalAPI()
    this.notifications.clear()
  }

  setupGlobalAPI() {
    // Make notification system available globally
    window.NotificationSystem = this
    
    // Legacy API compatibility
    window.showToast = (message, type = 'info') => this.show(message, { type })
    window.showSuccess = (message) => this.success(message)
    window.showError = (message) => this.error(message)
    window.showWarning = (message) => this.warning(message)
    window.showInfo = (message) => this.info(message)
  }

  removeGlobalAPI() {
    delete window.NotificationSystem
    delete window.showToast
    delete window.showSuccess
    delete window.showError
    delete window.showWarning
    delete window.showInfo
  }

  setupPositioning() {
    const positions = {
      'top-right': 'top-20 right-4',
      'top-left': 'top-20 left-4',
      'bottom-right': 'bottom-4 right-4',
      'bottom-left': 'bottom-4 left-4',
      'top-center': 'top-20 left-1/2 -translate-x-1/2',
      'bottom-center': 'bottom-4 left-1/2 -translate-x-1/2'
    }

    const positionClasses = positions[this.positionValue] || positions['top-right']
    this.element.className = `fixed ${positionClasses} z-[9999] space-y-2 max-w-sm pointer-events-none`
  }

  show(message, options = {}) {
    const defaults = {
      type: 'info',
      duration: this.defaultDurationValue,
      showProgress: true,
      closable: true,
      persist: false,
      id: `notification-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    }

    const config = { ...defaults, ...options }
    const notification = this.createNotification(message, config)
    
    this.addToContainer(notification)
    this.notifications.set(config.id, { element: notification, config })
    
    // Limit number of notifications
    this.enforceMaxNotifications()
    
    // Auto dismiss if not persistent
    if (!config.persist && config.duration > 0) {
      this.scheduleDismiss(config.id, config.duration)
    }
    
    return config.id
  }

  createNotification(message, config) {
    const notification = document.createElement('div')
    notification.id = config.id
    notification.className = this.getNotificationClasses(config.type)
    notification.setAttribute('role', 'alert')
    notification.setAttribute('aria-live', config.type === 'error' ? 'assertive' : 'polite')
    
    notification.innerHTML = `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          ${this.getIcon(config.type)}
        </div>
        <div class="ml-3 flex-1">
          <p class="text-sm font-medium">${this.escapeHtml(message)}</p>
        </div>
        ${config.closable ? `
          <div class="ml-4 flex-shrink-0 flex">
            <button type="button" 
                    class="inline-flex text-current opacity-70 hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-current rounded-md p-1"
                    data-notification-id="${config.id}"
                    data-action="click->notification-system#dismiss">
              <span class="sr-only">Close</span>
              <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>
        ` : ''}
      </div>
      ${config.showProgress && !config.persist ? `
        <div class="mt-2 h-1 bg-current opacity-20 rounded-full overflow-hidden">
          <div class="h-full bg-current opacity-50 rounded-full notification-progress progress-shrink" 
               style="--duration: ${config.duration}ms"></div>
        </div>
      ` : ''}
    `
    
    // Add entrance animation
    notification.classList.add('animate-slide-in')
    
    return notification
  }

  getNotificationClasses(type) {
    const baseClasses = 'pointer-events-auto max-w-sm w-full shadow-lg rounded-lg p-4 mb-2 transform transition-all duration-300'
    
    const typeClasses = {
      success: 'bg-gradient-to-r from-green-50 to-emerald-50 text-green-800 border border-green-200',
      error: 'bg-gradient-to-r from-red-50 to-rose-50 text-red-800 border border-red-200',
      warning: 'bg-gradient-to-r from-yellow-50 to-amber-50 text-yellow-800 border border-yellow-200',
      info: 'bg-gradient-to-r from-blue-50 to-indigo-50 text-blue-800 border border-blue-200'
    }
    
    return `${baseClasses} ${typeClasses[type] || typeClasses.info}`
  }

  getIcon(type) {
    const icons = {
      success: `<svg class="h-6 w-6 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      error: `<svg class="h-6 w-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      warning: `<svg class="h-6 w-6 text-yellow-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>`,
      info: `<svg class="h-6 w-6 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`
    }
    
    return icons[type] || icons.info
  }

  addToContainer(notification) {
    if (this.hasContainerTarget) {
      this.containerTarget.appendChild(notification)
    } else {
      this.element.appendChild(notification)
    }
  }

  enforceMaxNotifications() {
    const notifications = this.element.querySelectorAll('.pointer-events-auto')
    
    if (notifications.length > this.maxNotificationsValue) {
      const excess = notifications.length - this.maxNotificationsValue
      for (let i = 0; i < excess; i++) {
        const oldestId = notifications[i].id
        this.dismiss({ params: { id: oldestId } })
      }
    }
  }

  scheduleDismiss(id, duration) {
    setTimeout(() => {
      if (this.notifications.has(id)) {
        this.dismiss({ params: { id } })
      }
    }, duration)
  }

  dismiss(event) {
    const id = event.params?.id || event.currentTarget.dataset.notificationId
    const notification = this.notifications.get(id)
    
    if (notification) {
      const element = notification.element
      
      // Add exit animation
      element.classList.remove('animate-slide-in')
      element.classList.add('animate-slide-out')
      
      // Remove after animation
      setTimeout(() => {
        element.remove()
        this.notifications.delete(id)
      }, 300)
    }
  }

  // Convenience methods
  success(message, options = {}) {
    return this.show(message, { ...options, type: 'success' })
  }

  error(message, options = {}) {
    return this.show(message, { ...options, type: 'error' })
  }

  warning(message, options = {}) {
    return this.show(message, { ...options, type: 'warning' })
  }

  info(message, options = {}) {
    return this.show(message, { ...options, type: 'info' })
  }

  // Clear all notifications
  clear() {
    this.notifications.forEach((_, id) => {
      this.dismiss({ params: { id } })
    })
  }

  // Utility method to escape HTML
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}