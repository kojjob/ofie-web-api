import { Controller } from "@hotwired/stimulus"
import { ErrorHandlingMixin } from "../mixins/error_handling_mixin"

export default class extends ErrorHandlingMixin(Controller) {
  static values = { propertyId: Number }
  static targets = ["button", "loading"]

  connect() {
    this.checkFavoriteStatus()
  }

  async toggle() {
    // Disable button during operation
    this.disableInteraction()
    
    const result = await this.handleAsync(
      async () => {
        const response = await fetch(`/properties/${this.propertyIdValue}/favorite`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          credentials: 'same-origin'
        })

        if (!response.ok) {
          if (response.status === 401) {
            // Special handling for authentication
            const error = new Error('Authentication required')
            error.status = 401
            error.requiresAuth = true
            throw error
          }
          throw new Error(`HTTP ${response.status}`)
        }

        return response.json()
      },
      {
        onError: (error) => {
          if (error.status === 401 || error.requiresAuth) {
            this.showNotification('Please log in to save properties', 'error')
            setTimeout(() => {
              window.location.href = '/users/sign_in'
            }, 1500)
          } else {
            this.showNotification('Failed to update favorite status. Please try again.', 'error')
          }
        },
        onFinally: () => {
          this.enableInteraction()
        },
        retries: 1,
        retryDelay: 1000
      }
    )

    if (result.success) {
      this.updateButtonState(result.data.favorited)
      this.showNotification(
        result.data.favorited ? 'Added to favorites' : 'Removed from favorites'
      )
    }
  }

  async checkFavoriteStatus() {
    const result = await this.handleAsync(
      async () => {
        const response = await fetch(`/properties/${this.propertyIdValue}/favorite_status`, {
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          credentials: 'same-origin'
        })

        if (response.ok) {
          return response.json()
        }
        
        // Don't throw error for status check - just return null
        return null
      },
      {
        showNotification: false,
        retries: 0
      }
    )

    if (result.success && result.data) {
      this.updateButtonState(result.data.favorited)
    }
  }

  updateButtonState(isFavorited) {
    const svg = this.element.querySelector('svg')
    const span = this.element.querySelector('span')
    
    if (isFavorited) {
      // Filled heart for favorited
      svg.setAttribute('fill', 'currentColor')
      svg.setAttribute('stroke', 'none')
      this.element.classList.remove('text-gray-700', 'hover:text-red-500')
      this.element.classList.add('text-red-500', 'hover:text-red-600')
      this.element.classList.remove('border-gray-300', 'hover:border-red-500')
      this.element.classList.add('border-red-500', 'hover:border-red-600')
      span.textContent = 'Saved'
    } else {
      // Outline heart for not favorited
      svg.setAttribute('fill', 'none')
      svg.setAttribute('stroke', 'currentColor')
      this.element.classList.remove('text-red-500', 'hover:text-red-600')
      this.element.classList.add('text-gray-700', 'hover:text-red-500')
      this.element.classList.remove('border-red-500', 'hover:border-red-600')
      this.element.classList.add('border-gray-300', 'hover:border-red-500')
      span.textContent = 'Save'
    }
  }

  showNotification(message, type = 'success') {
    // Use the unified notification system if available
    if (window.NotificationSystem) {
      window.NotificationSystem[type](message)
      return
    }
    
    // Fallback to simple notification
    const notification = document.createElement('div')
    const bgColor = type === 'success' ? 'bg-green-50 border-green-200 text-green-700' : 'bg-red-50 border-red-200 text-red-700'
    
    notification.className = `fixed top-24 right-4 ${bgColor} border px-6 py-4 rounded-lg shadow-lg z-notification transition-all-300 animate-slide-in`
    notification.innerHTML = `
      <div class="flex items-center">
        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          ${type === 'success' 
            ? '<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>'
            : '<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path>'
          }
        </svg>
        <span>${message}</span>
      </div>
    `
    
    document.body.appendChild(notification)
    
    // Remove notification after 3 seconds
    setTimeout(() => {
      notification.classList.remove('animate-slide-in')
      notification.classList.add('animate-slide-out')
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }

  // Override to show/hide loading state if we have a loading target
  showLoadingState() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
    
    // Add loading state to button
    const svg = this.element.querySelector('svg')
    if (svg) {
      svg.classList.add('animate-pulse')
    }
  }

  hideLoadingState() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
    
    // Remove loading state from button
    const svg = this.element.querySelector('svg')
    if (svg) {
      svg.classList.remove('animate-pulse')
    }
  }
};
