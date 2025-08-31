import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    propertyUrl: String,
    propertyTitle: String
  }

  openModal() {
    // Check if Web Share API is supported
    if (navigator.share) {
      this.nativeShare()
    } else {
      this.showShareModal()
    }
  }

  async nativeShare() {
    try {
      await navigator.share({
        title: this.propertyTitleValue,
        text: `Check out this property: ${this.propertyTitleValue}`,
        url: this.propertyUrlValue
      })
      this.showNotification('Property shared successfully!')
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Error sharing:', error)
        this.showShareModal() // Fallback to custom modal
      }
    }
  }

  showShareModal() {
    // Create modal overlay
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-50'
    modal.innerHTML = `
      <div class="flex items-center justify-center min-h-screen p-4">
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Share Property</h3>
            <button class="close-modal text-gray-400 hover:text-gray-600">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </button>
          </div>
          
          <div class="space-y-4">
            <div class="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
              <input type="text" value="${this.propertyUrlValue}" readonly 
                     class="flex-1 bg-transparent text-sm text-gray-600 outline-none" id="share-url">
              <button class="copy-url bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-sm font-medium transition-colors">
                Copy
              </button>
            </div>
            
            <div class="grid grid-cols-2 gap-3">
              <button class="share-facebook flex items-center justify-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white p-3 rounded-lg transition-colors">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                </svg>
                <span class="text-sm">Facebook</span>
              </button>
              
              <button class="share-twitter flex items-center justify-center space-x-2 bg-sky-500 hover:bg-sky-600 text-white p-3 rounded-lg transition-colors">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
                </svg>
                <span class="text-sm">Twitter</span>
              </button>
              
              <button class="share-whatsapp flex items-center justify-center space-x-2 bg-green-500 hover:bg-green-600 text-white p-3 rounded-lg transition-colors">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.885 3.488"/>
                </svg>
                <span class="text-sm">WhatsApp</span>
              </button>
              
              <button class="share-email flex items-center justify-center space-x-2 bg-gray-600 hover:bg-gray-700 text-white p-3 rounded-lg transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                </svg>
                <span class="text-sm">Email</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
    document.body.style.overflow = 'hidden'
    
    // Add event listeners
    this.setupModalEventListeners(modal)
  }

  setupModalEventListeners(modal) {
    // Close modal
    const closeBtn = modal.querySelector('.close-modal')
    closeBtn.addEventListener('click', () => this.closeModal(modal))
    
    // Close on overlay click
    modal.addEventListener('click', (e) => {
      if (e.target === modal) this.closeModal(modal)
    })
    
    // Copy URL
    const copyBtn = modal.querySelector('.copy-url')
    copyBtn.addEventListener('click', () => this.copyToClipboard(modal))
    
    // Social sharing
    modal.querySelector('.share-facebook').addEventListener('click', () => this.shareToFacebook())
    modal.querySelector('.share-twitter').addEventListener('click', () => this.shareToTwitter())
    modal.querySelector('.share-whatsapp').addEventListener('click', () => this.shareToWhatsApp())
    modal.querySelector('.share-email').addEventListener('click', () => this.shareToEmail())
  }

  closeModal(modal) {
    document.body.style.overflow = 'auto'
    modal.remove()
  }

  async copyToClipboard(modal) {
    try {
      await navigator.clipboard.writeText(this.propertyUrlValue)
      const copyBtn = modal.querySelector('.copy-url')
      const originalText = copyBtn.textContent
      copyBtn.textContent = 'Copied!'
      copyBtn.classList.add('bg-green-600')
      copyBtn.classList.remove('bg-blue-600')
      
      setTimeout(() => {
        copyBtn.textContent = originalText
        copyBtn.classList.remove('bg-green-600')
        copyBtn.classList.add('bg-blue-600')
      }, 2000)
      
      this.showNotification('Link copied to clipboard!')
    } catch (error) {
      console.error('Failed to copy:', error)
      this.showNotification('Failed to copy link', 'error')
    }
  }

  shareToFacebook() {
    const url = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(this.propertyUrlValue)}`
    this.openShareWindow(url)
  }

  shareToTwitter() {
    const text = `Check out this property: ${this.propertyTitleValue}`
    const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(this.propertyUrlValue)}`
    this.openShareWindow(url)
  }

  shareToWhatsApp() {
    const text = `Check out this property: ${this.propertyTitleValue} ${this.propertyUrlValue}`
    const url = `https://wa.me/?text=${encodeURIComponent(text)}`
    this.openShareWindow(url)
  }

  shareToEmail() {
    const subject = `Check out this property: ${this.propertyTitleValue}`
    const body = `I thought you might be interested in this property:\n\n${this.propertyTitleValue}\n${this.propertyUrlValue}`
    const url = `mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`
    window.location.href = url
  }

  openShareWindow(url) {
    window.open(url, 'share', 'width=600,height=400,scrollbars=yes,resizable=yes')
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
};
