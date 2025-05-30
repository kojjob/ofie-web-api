import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { phone: String }

  call() {
    const phone = this.phoneValue
    
    if (!phone || phone.trim() === '') {
      this.showContactModal()
      return
    }
    
    // Clean phone number (remove spaces, dashes, parentheses)
    const cleanPhone = phone.replace(/[\s\-\(\)]/g, '')
    
    // Check if it's a mobile device
    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
    
    if (isMobile) {
      // On mobile, directly initiate call
      window.location.href = `tel:${cleanPhone}`
    } else {
      // On desktop, show call options modal
      this.showCallOptionsModal(phone, cleanPhone)
    }
  }

  showCallOptionsModal(displayPhone, cleanPhone) {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-50'
    modal.innerHTML = `
      <div class="flex items-center justify-center min-h-screen p-4">
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full p-6">
          <div class="text-center">
            <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 mb-4">
              <svg class="h-6 w-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path>
              </svg>
            </div>
            
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Call Property Owner</h3>
            <p class="text-gray-600 mb-6">Choose how you'd like to contact the property owner:</p>
            
            <div class="space-y-3">
              <div class="bg-gray-50 p-4 rounded-lg">
                <div class="text-sm text-gray-600 mb-2">Phone Number:</div>
                <div class="text-lg font-semibold text-gray-900">${displayPhone}</div>
              </div>
              
              <div class="grid grid-cols-1 gap-3">
                <button class="call-direct bg-blue-600 hover:bg-blue-700 text-white px-4 py-3 rounded-lg font-medium transition-colors duration-200 flex items-center justify-center space-x-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path>
                  </svg>
                  <span>Call Now</span>
                </button>
                
                <button class="copy-phone bg-white border border-gray-300 hover:border-blue-500 text-gray-700 hover:text-blue-600 px-4 py-3 rounded-lg font-medium transition-colors duration-200 flex items-center justify-center space-x-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                  </svg>
                  <span>Copy Number</span>
                </button>
              </div>
            </div>
            
            <button class="close-modal mt-4 text-gray-500 hover:text-gray-700 text-sm font-medium">
              Cancel
            </button>
          </div>
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
    document.body.style.overflow = 'hidden'
    
    // Add event listeners
    this.setupCallModalEventListeners(modal, cleanPhone, displayPhone)
  }

  setupCallModalEventListeners(modal, cleanPhone, displayPhone) {
    // Close modal
    const closeBtn = modal.querySelector('.close-modal')
    closeBtn.addEventListener('click', () => this.closeModal(modal))
    
    // Close on overlay click
    modal.addEventListener('click', (e) => {
      if (e.target === modal) this.closeModal(modal)
    })
    
    // Call direct
    const callBtn = modal.querySelector('.call-direct')
    callBtn.addEventListener('click', () => {
      window.location.href = `tel:${cleanPhone}`
      this.closeModal(modal)
    })
    
    // Copy phone number
    const copyBtn = modal.querySelector('.copy-phone')
    copyBtn.addEventListener('click', () => this.copyPhoneNumber(displayPhone, copyBtn))
  }

  showContactModal() {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-50'
    modal.innerHTML = `
      <div class="flex items-center justify-center min-h-screen p-4">
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full p-6">
          <div class="text-center">
            <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-yellow-100 mb-4">
              <svg class="h-6 w-6 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
              </svg>
            </div>
            
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Contact Information Not Available</h3>
            <p class="text-gray-600 mb-6">The property owner's phone number is not available. You can still contact them using the "Send Message" button.</p>
            
            <div class="space-y-3">
              <button class="send-message-instead bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-medium transition-colors duration-200 flex items-center justify-center space-x-2 w-full">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.959 8.959 0 01-4.906-1.456L3 21l2.456-5.094A8.959 8.959 0 013 12c0-4.418 3.582-8 8-8s8 3.582 8 8z"></path>
                </svg>
                <span>Send Message Instead</span>
              </button>
            </div>
            
            <button class="close-modal mt-4 text-gray-500 hover:text-gray-700 text-sm font-medium">
              Close
            </button>
          </div>
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
    document.body.style.overflow = 'hidden'
    
    // Add event listeners
    this.setupContactModalEventListeners(modal)
  }

  setupContactModalEventListeners(modal) {
    // Close modal
    const closeBtn = modal.querySelector('.close-modal')
    closeBtn.addEventListener('click', () => this.closeModal(modal))
    
    // Close on overlay click
    modal.addEventListener('click', (e) => {
      if (e.target === modal) this.closeModal(modal)
    })
    
    // Send message instead
    const messageBtn = modal.querySelector('.send-message-instead')
    messageBtn.addEventListener('click', () => {
      this.closeModal(modal)
      // Trigger the messaging modal
      const messagingBtn = document.querySelector('[data-controller="messaging"]')
      if (messagingBtn) {
        messagingBtn.click()
      }
    })
  }

  closeModal(modal) {
    document.body.style.overflow = 'auto'
    modal.remove()
  }

  async copyPhoneNumber(phone, button) {
    try {
      await navigator.clipboard.writeText(phone)
      
      const originalContent = button.innerHTML
      button.innerHTML = `
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
        </svg>
        <span>Copied!</span>
      `
      button.classList.add('bg-green-50', 'border-green-300', 'text-green-700')
      button.classList.remove('bg-white', 'border-gray-300', 'text-gray-700', 'hover:border-blue-500', 'hover:text-blue-600')
      
      setTimeout(() => {
        button.innerHTML = originalContent
        button.classList.remove('bg-green-50', 'border-green-300', 'text-green-700')
        button.classList.add('bg-white', 'border-gray-300', 'text-gray-700', 'hover:border-blue-500', 'hover:text-blue-600')
      }, 2000)
      
      this.showNotification('Phone number copied to clipboard!')
    } catch (error) {
      console.error('Failed to copy phone number:', error)
      this.showNotification('Failed to copy phone number', 'error')
    }
  }

  showNotification(message, type = 'success') {
    const notification = document.createElement('div')
    const bgColor = type === 'success' ? 'bg-green-50 border-green-200 text-green-700' : 'bg-red-50 border-red-200 text-red-700'
    
    notification.className = `fixed top-4 right-4 ${bgColor} border px-6 py-4 rounded-lg shadow-lg z-50 transition-all duration-300`
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
      notification.style.opacity = '0'
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }
}