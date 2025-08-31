import { Controller } from "@hotwired/stimulus"

// Modal controller for dynamic modal management
export default class extends Controller {
  static targets = ["container", "backdrop", "content"]
  static values = { 
    open: Boolean,
    closeOnEscape: { type: Boolean, default: true },
    closeOnBackdrop: { type: Boolean, default: true }
  }

  connect() {
    // Add event listener for escape key
    if (this.closeOnEscapeValue) {
      this.boundHandleEscape = this.handleEscape.bind(this)
      document.addEventListener('keydown', this.boundHandleEscape)
    }

    // Show modal if open value is true
    if (this.openValue) {
      this.show()
    }
  }

  disconnect() {
    if (this.boundHandleEscape) {
      document.removeEventListener('keydown', this.boundHandleEscape)
    }
  }

  // Show the modal
  show(event) {
    if (event) event.preventDefault()
    
    this.openValue = true
    this.containerTarget.classList.remove('hidden')
    
    // Animate in
    requestAnimationFrame(() => {
      this.containerTarget.classList.add('modal-open')
      this.backdropTarget.classList.add('opacity-50')
      this.contentTarget.classList.add('scale-100', 'opacity-100')
      this.contentTarget.classList.remove('scale-95', 'opacity-0')
    })

    // Prevent body scroll
    document.body.style.overflow = 'hidden'
    
    // Dispatch custom event
    this.dispatch('shown')
  }

  // Hide the modal
  hide(event) {
    if (event) event.preventDefault()
    
    this.openValue = false
    
    // Animate out
    this.containerTarget.classList.remove('modal-open')
    this.backdropTarget.classList.remove('opacity-50')
    this.contentTarget.classList.remove('scale-100', 'opacity-100')
    this.contentTarget.classList.add('scale-95', 'opacity-0')
    
    // Hide after animation
    setTimeout(() => {
      if (!this.openValue) {
        this.containerTarget.classList.add('hidden')
      }
    }, 200)

    // Restore body scroll
    document.body.style.overflow = ''
    
    // Dispatch custom event
    this.dispatch('hidden')
  }

  // Toggle modal visibility
  toggle(event) {
    if (event) event.preventDefault()
    
    if (this.openValue) {
      this.hide()
    } else {
      this.show()
    }
  }

  // Handle backdrop click
  handleBackdropClick(event) {
    if (this.closeOnBackdropValue && event.target === this.backdropTarget) {
      this.hide()
    }
  }

  // Handle escape key
  handleEscape(event) {
    if (this.openValue && event.key === 'Escape') {
      this.hide()
    }
  }

  // Load content via AJAX
  async loadContent(event) {
    event.preventDefault()
    
    const url = event.currentTarget.dataset.modalUrl || event.currentTarget.href
    
    if (!url) return
    
    try {
      // Show loading state
      this.contentTarget.innerHTML = '<div class="text-center py-8"><div class="spinner"></div></div>'
      this.show()
      
      const response = await fetch(url, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const html = await response.text()
      this.contentTarget.innerHTML = html
      
      // Dispatch event for content loaded
      this.dispatch('content-loaded')
    } catch (error) {
      console.error('Error loading modal content:', error)
      this.contentTarget.innerHTML = `
        <div class="text-center py-8">
          <p class="text-red-600">Error loading content</p>
          <button data-action="click->modal#hide" class="mt-4 px-4 py-2 bg-gray-200 rounded">Close</button>
        </div>
      `
    }
  }

  // Confirm action before proceeding
  confirm(event) {
    const message = event.currentTarget.dataset.confirmMessage || 'Are you sure?'
    
    if (!confirm(message)) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }
    
    // If confirmed and has a URL, navigate
    const url = event.currentTarget.dataset.confirmUrl
    if (url) {
      window.location.href = url
    }
  }
};
