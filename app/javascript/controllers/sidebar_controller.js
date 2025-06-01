import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["sidebar", "overlay"]
  
  connect() {
    // Initialize sidebar state
    this.isOpen = false
    
    // Handle window resize
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener('resize', this.handleResize)
    
    // Handle escape key
    this.handleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.handleEscape)
    
    // Set initial state based on screen size
    this.handleResize()
  }
  
  disconnect() {
    window.removeEventListener('resize', this.handleResize)
    document.removeEventListener('keydown', this.handleEscape)
  }
  
  open() {
    if (window.innerWidth < 1024) { // lg breakpoint
      this.isOpen = true
      this.sidebarTarget.classList.remove('-translate-x-full')
      this.sidebarTarget.classList.add('translate-x-0')
      this.overlayTarget.classList.remove('hidden')
      
      // Prevent body scroll
      document.body.classList.add('overflow-hidden')
      
      // Focus trap
      this.trapFocus()
    }
  }
  
  close() {
    if (window.innerWidth < 1024) { // lg breakpoint
      this.isOpen = false
      this.sidebarTarget.classList.remove('translate-x-0')
      this.sidebarTarget.classList.add('-translate-x-full')
      this.overlayTarget.classList.add('hidden')
      
      // Restore body scroll
      document.body.classList.remove('overflow-hidden')
    }
  }
  
  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }
  
  handleResize() {
    if (window.innerWidth >= 1024) { // lg breakpoint
      // Desktop: always show sidebar, hide overlay
      this.sidebarTarget.classList.remove('-translate-x-full')
      this.sidebarTarget.classList.add('translate-x-0')
      this.overlayTarget.classList.add('hidden')
      document.body.classList.remove('overflow-hidden')
      this.isOpen = false
    } else {
      // Mobile: hide sidebar by default
      if (!this.isOpen) {
        this.sidebarTarget.classList.add('-translate-x-full')
        this.sidebarTarget.classList.remove('translate-x-0')
        this.overlayTarget.classList.add('hidden')
      }
    }
  }
  
  handleEscape(event) {
    if (event.key === 'Escape' && this.isOpen) {
      this.close()
    }
  }
  
  trapFocus() {
    // Simple focus trap for accessibility
    const focusableElements = this.sidebarTarget.querySelectorAll(
      'a[href], button, textarea, input[type="text"], input[type="radio"], input[type="checkbox"], select'
    )
    
    if (focusableElements.length > 0) {
      focusableElements[0].focus()
    }
  }
  
  // Handle link clicks on mobile to close sidebar
  linkClicked() {
    if (window.innerWidth < 1024) {
      this.close()
    }
  }
}
