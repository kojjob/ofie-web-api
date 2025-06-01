import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    propertyId: Number,
    ownerId: Number
  }

  openModal() {
    this.createMessageModal()
  }

  createMessageModal() {
    // Create modal overlay
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-50'
    modal.innerHTML = `
      <div class="flex items-center justify-center min-h-screen p-4">
        <div class="bg-white rounded-2xl shadow-2xl max-w-lg w-full">
          <form class="message-form">
            <!-- Modal Header -->
            <div class="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-4 rounded-t-2xl">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold text-white">Send Message to Property Owner</h3>
                <button type="button" class="close-modal text-white hover:text-gray-200 transition-colors">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                  </svg>
                </button>
              </div>
            </div>
            
            <!-- Modal Body -->
            <div class="px-6 py-6 space-y-4">
              <div class="space-y-2">
                <label class="block text-sm font-medium text-gray-700">Subject</label>
                <select class="subject-select w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors" required>
                  <option value="">Select a subject</option>
                  <option value="Property Inquiry">Property Inquiry</option>
                  <option value="Viewing Request">Viewing Request</option>
                  <option value="Rental Application">Rental Application</option>
                  <option value="General Question">General Question</option>
                  <option value="Other">Other</option>
                </select>
              </div>
              
              <div class="space-y-2">
                <label class="block text-sm font-medium text-gray-700">Your Name</label>
                <input type="text" class="sender-name w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors" placeholder="Enter your name" required>
              </div>
              
              <div class="space-y-2">
                <label class="block text-sm font-medium text-gray-700">Your Email</label>
                <input type="email" class="sender-email w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors" placeholder="Enter your email" required>
              </div>
              
              <div class="space-y-2">
                <label class="block text-sm font-medium text-gray-700">Your Phone (Optional)</label>
                <input type="tel" class="sender-phone w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors" placeholder="Enter your phone number">
              </div>
              
              <div class="space-y-2">
                <label class="block text-sm font-medium text-gray-700">Message</label>
                <textarea class="message-content w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-colors" rows="4" placeholder="Write your message here..." required></textarea>
              </div>
              
              <div class="text-sm text-gray-600 bg-blue-50 p-3 rounded-lg">
                <div class="flex items-start space-x-2">
                  <svg class="w-4 h-4 text-blue-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path>
                  </svg>
                  <span>Your message will be sent directly to the property owner. They will receive your contact information to respond to your inquiry.</span>
                </div>
              </div>
            </div>
            
            <!-- Modal Footer -->
            <div class="px-6 py-4 bg-gray-50 rounded-b-2xl flex justify-end space-x-3">
              <button type="button" class="close-modal px-4 py-2 text-gray-600 hover:text-gray-800 font-medium transition-colors">
                Cancel
              </button>
              <button type="submit" class="send-message-btn bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium transition-colors duration-200">
                <span class="btn-text">Send Message</span>
                <span class="btn-loading hidden">
                  <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Sending...
                </span>
              </button>
            </div>
          </form>
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
    document.body.style.overflow = 'hidden'
    
    // Add event listeners
    this.setupModalEventListeners(modal)
    
    // Focus first input
    setTimeout(() => {
      const firstInput = modal.querySelector('.subject-select')
      if (firstInput) firstInput.focus()
    }, 100)
  }

  setupModalEventListeners(modal) {
    // Close modal
    const closeBtns = modal.querySelectorAll('.close-modal')
    closeBtns.forEach(btn => {
      btn.addEventListener('click', () => this.closeModal(modal))
    })
    
    // Close on overlay click
    modal.addEventListener('click', (e) => {
      if (e.target === modal) this.closeModal(modal)
    })
    
    // Close on Escape key
    const escapeHandler = (e) => {
      if (e.key === 'Escape') {
        this.closeModal(modal)
        document.removeEventListener('keydown', escapeHandler)
      }
    }
    document.addEventListener('keydown', escapeHandler)
    
    // Handle form submission
    const form = modal.querySelector('.message-form')
    form.addEventListener('submit', (e) => {
      e.preventDefault()
      this.sendMessage(modal)
    })
  }

  closeModal(modal) {
    document.body.style.overflow = 'auto'
    modal.remove()
  }

  async sendMessage(modal) {
    const form = modal.querySelector('.message-form')
    const submitBtn = modal.querySelector('.send-message-btn')
    const btnText = submitBtn.querySelector('.btn-text')
    const btnLoading = submitBtn.querySelector('.btn-loading')
    
    // Get form data
    const formData = {
      subject: modal.querySelector('.subject-select').value,
      sender_name: modal.querySelector('.sender-name').value,
      sender_email: modal.querySelector('.sender-email').value,
      sender_phone: modal.querySelector('.sender-phone').value,
      message: modal.querySelector('.message-content').value,
      property_id: this.propertyIdValue,
      owner_id: this.ownerIdValue
    }
    
    // Validate required fields
    if (!formData.subject || !formData.sender_name || !formData.sender_email || !formData.message) {
      this.showNotification('Please fill in all required fields', 'error')
      return
    }
    
    // Show loading state
    submitBtn.disabled = true
    btnText.classList.add('hidden')
    btnLoading.classList.remove('hidden')
    
    try {
      const response = await fetch('/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ message: formData }),
        credentials: 'same-origin'
      })
      
      if (response.ok) {
        this.closeModal(modal)
        this.showNotification('Message sent successfully! The property owner will contact you soon.')
      } else {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to send message')
      }
    } catch (error) {
      console.error('Error sending message:', error)
      this.showNotification(error.message || 'Failed to send message. Please try again.', 'error')
    } finally {
      // Reset button state
      submitBtn.disabled = false
      btnText.classList.remove('hidden')
      btnLoading.classList.add('hidden')
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
    
    // Remove notification after 5 seconds
    setTimeout(() => {
      notification.style.opacity = '0'
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => notification.remove(), 300)
    }, 5000)
  }
}