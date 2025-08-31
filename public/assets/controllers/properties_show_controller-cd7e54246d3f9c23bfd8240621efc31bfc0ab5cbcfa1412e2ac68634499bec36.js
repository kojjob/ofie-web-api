import { Controller } from "@hotwired/stimulus"

// Professional Property Show Controller - 2025 Design
export default class extends Controller {
  static targets = ["favoriteButton", "shareButton", "reportButton"]
  static values = { 
    propertyId: String,
    propertyTitle: String,
    propertyPrice: Number,
    propertyAddress: String
  }

  connect() {
    console.log("Professional property show controller connected")
    this.initializeAnalytics()
    this.setupKeyboardShortcuts()
  }

  disconnect() {
    this.removeKeyboardShortcuts()
  }

  // Enhanced favorite functionality with visual feedback
  toggleFavorite(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const icon = button.querySelector('svg')
    const isFavorited = button.classList.contains('favorited')
    
    // Optimistic UI update
    if (isFavorited) {
      button.classList.remove('favorited', 'text-red-500')
      button.classList.add('text-gray-600')
      this.showNotification('Removed from favorites', 'success')
    } else {
      button.classList.add('favorited', 'text-red-500')
      button.classList.remove('text-gray-600')
      this.showNotification('Added to favorites', 'success')
    }
    
    // Add micro-interaction
    button.style.transform = 'scale(0.95)'
    setTimeout(() => {
      button.style.transform = 'scale(1)'
    }, 150)
    
    // Here you would make the API call
    this.saveFavoriteStatus(!isFavorited)
  }

  // Professional sharing functionality
  shareProperty(event) {
    event.preventDefault()
    
    const shareData = {
      title: this.propertyTitleValue || 'Amazing Property',
      text: `Check out this property for $${this.propertyPriceValue?.toLocaleString()}/month`,
      url: window.location.href
    }
    
    if (navigator.share && navigator.canShare && navigator.canShare(shareData)) {
      navigator.share(shareData).catch(err => {
        console.log('Error sharing:', err)
        this.fallbackShare()
      })
    } else {
      this.fallbackShare()
    }
  }

  // Advanced share fallback with multiple options
  fallbackShare() {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(window.location.href).then(() => {
        this.showNotification('Link copied to clipboard!', 'success')
      }).catch(() => {
        this.showShareModal()
      })
    } else {
      this.showShareModal()
    }
  }

  // Show share modal with social options
  showShareModal() {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50'
    modal.innerHTML = `
      <div class="bg-white rounded-lg p-6 max-w-sm mx-4">
        <h3 class="text-lg font-semibold mb-4">Share this property</h3>
        <div class="space-y-3">
          <button onclick="this.shareToFacebook()" class="w-full flex items-center justify-center px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors">
            Share on Facebook
          </button>
          <button onclick="this.shareToTwitter()" class="w-full flex items-center justify-center px-4 py-2 bg-blue-400 text-white rounded hover:bg-blue-500 transition-colors">
            Share on Twitter
          </button>
          <button onclick="this.copyLink()" class="w-full flex items-center justify-center px-4 py-2 border border-gray-300 text-gray-700 rounded hover:bg-gray-50 transition-colors">
            Copy Link
          </button>
        </div>
        <button onclick="this.remove()" class="mt-4 w-full text-gray-500 hover:text-gray-700">
          Cancel
        </button>
      </div>
    `
    
    document.body.appendChild(modal)
    
    // Auto-remove after 10 seconds
    setTimeout(() => {
      if (modal.parentNode) modal.remove()
    }, 10000)
  }

  // Report issue functionality
  reportIssue(event) {
    event.preventDefault()
    
    const reasons = [
      'Inaccurate information',
      'Inappropriate content',
      'Suspected fraud',
      'Property no longer available',
      'Other'
    ]
    
    this.showReportModal(reasons)
  }

  showReportModal(reasons) {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50'
    
    const reasonOptions = reasons.map(reason => 
      `<label class="flex items-center space-x-2">
        <input type="radio" name="report-reason" value="${reason}" class="text-blue-600">
        <span>${reason}</span>
      </label>`
    ).join('')
    
    modal.innerHTML = `
      <div class="bg-white rounded-lg p-6 max-w-md mx-4">
        <h3 class="text-lg font-semibold mb-4">Report an issue</h3>
        <div class="space-y-3 mb-4">
          ${reasonOptions}
        </div>
        <textarea placeholder="Additional details (optional)" class="w-full p-3 border border-gray-300 rounded resize-none" rows="3"></textarea>
        <div class="flex space-x-3 mt-4">
          <button onclick="this.submitReport()" class="flex-1 bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700 transition-colors">
            Submit Report
          </button>
          <button onclick="this.remove()" class="flex-1 border border-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-50 transition-colors">
            Cancel
          </button>
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
  }

  // Professional notification system
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    const bgColor = type === 'success' ? 'bg-green-500' : type === 'error' ? 'bg-red-500' : 'bg-blue-500'
    
    notification.className = `fixed top-20 right-4 ${bgColor} text-white px-6 py-3 rounded-lg shadow-lg z-[9999] transform translate-x-full transition-transform duration-300`
    notification.textContent = message
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)'
    }, 100)
    
    // Animate out and remove
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }

  // Analytics tracking
  initializeAnalytics() {
    // Track property view
    if (typeof gtag !== 'undefined') {
      gtag('event', 'property_view', {
        property_id: this.propertyIdValue,
        property_price: this.propertyPriceValue,
        property_location: this.propertyAddressValue
      })
    }
  }

  // Keyboard shortcuts for power users
  setupKeyboardShortcuts() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.keydownHandler)
  }

  removeKeyboardShortcuts() {
    if (this.keydownHandler) {
      document.removeEventListener('keydown', this.keydownHandler)
    }
  }

  handleKeydown(event) {
    // Only handle shortcuts when not in form fields
    if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') return
    
    switch(event.key) {
      case 'f':
      case 'F':
        if (this.hasFavoriteButtonTarget) {
          event.preventDefault()
          this.toggleFavorite({ preventDefault: () => {}, currentTarget: this.favoriteButtonTarget })
        }
        break
      case 's':
      case 'S':
        if (this.hasShareButtonTarget) {
          event.preventDefault()
          this.shareProperty({ preventDefault: () => {} })
        }
        break
    }
  }

  // API calls (to be implemented based on your backend)
  async saveFavoriteStatus(isFavorited) {
    try {
      const response = await fetch(`/properties/${this.propertyIdValue}/favorite`, {
        method: isFavorited ? 'POST' : 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
        }
      })
      
      if (!response.ok) {
        throw new Error('Failed to update favorite status')
      }
    } catch (error) {
      console.error('Error updating favorite status:', error)
      this.showNotification('Failed to update favorite status', 'error')
    }
  }

  async submitReport(reason, details) {
    try {
      const response = await fetch(`/properties/${this.propertyIdValue}/report`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          reason: reason,
          details: details
        })
      })
      
      if (response.ok) {
        this.showNotification('Report submitted successfully', 'success')
      } else {
        throw new Error('Failed to submit report')
      }
    } catch (error) {
      console.error('Error submitting report:', error)
      this.showNotification('Failed to submit report', 'error')
    }
  }
};
