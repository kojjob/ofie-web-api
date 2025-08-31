import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    type: String,
    duration: { type: Number, default: 5000 },
    position: { type: String, default: "top-right" },
    animation: { type: String, default: "slide" },
    dismissible: { type: Boolean, default: true }
  }

  connect() {
    this.setupMessage()
    this.startAutoHide()
  }

  setupMessage() {
    // Add base classes
    this.element.classList.add("flash-message")
    
    // Add type-specific classes
    this.element.classList.add(`flash-${this.typeValue}`)
    
    // Add position classes
    this.addPositionClasses()
    
    // Add animation classes
    this.addAnimationClasses()
    
    // Add icon and content structure
    this.enhanceContent()
    
    // Add dismissible functionality
    if (this.dismissibleValue) {
      this.addDismissButton()
    }
    
    // Apply styling
    this.applyStyles()
    
    // Add entrance animation
    this.animateEntrance()
  }

  enhanceContent() {
    const content = this.element.querySelector('.flash-content')
    if (content) {
      const originalContent = content.innerHTML
      const icon = this.getIcon(this.typeValue)
      
      content.innerHTML = `
        <div class="flex items-start space-x-3">
          <div class="flex-shrink-0 mt-0.5">
            ${icon}
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium">
              ${originalContent}
            </div>
          </div>
        </div>
      `
    }
  }

  getIcon(type) {
    const icons = {
      success: '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      error: '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      warning: '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path></svg>',
      info: '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      notice: '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
      alert: '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
    }
    
    return icons[type] || icons['info']
  }

  addPositionClasses() {
    const positions = {
      "top-left": "fixed top-24 left-4 z-[9999]",
      "top-right": "fixed top-24 right-4 z-[9999]",
      "top-center": "fixed top-24 left-1/2 transform -translate-x-1/2 z-[9999]",
      "bottom-left": "fixed bottom-4 left-4 z-[9999]",
      "bottom-right": "fixed bottom-4 right-4 z-[9999]",
      "bottom-center": "fixed bottom-4 left-1/2 transform -translate-x-1/2 z-[9999]",
      "center": "fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-[9999]",
      "inline": "relative w-full"
    }
    
    const positionClasses = positions[this.positionValue] || positions["inline"]
    this.element.className += ` ${positionClasses}`
  }

  addAnimationClasses() {
    const animations = {
      "slide": "transition-all duration-300 ease-in-out",
      "fade": "transition-opacity duration-300 ease-in-out",
      "bounce": "transition-all duration-300 ease-in-out",
      "pulse": "transition-all duration-300 ease-in-out",
      "none": ""
    }
    
    const animationClasses = animations[this.animationValue] || animations["slide"]
    if (animationClasses) {
      this.element.className += ` ${animationClasses}`
    }
  }

  applyStyles() {
    const typeStyles = {
      success: "bg-gradient-to-r from-green-500 to-green-600 text-white border-l-4 border-green-700 shadow-green-200",
      error: "bg-gradient-to-r from-red-500 to-red-600 text-white border-l-4 border-red-700 shadow-red-200",
      warning: "bg-gradient-to-r from-yellow-500 to-yellow-600 text-white border-l-4 border-yellow-700 shadow-yellow-200",
      info: "bg-gradient-to-r from-blue-500 to-blue-600 text-white border-l-4 border-blue-700 shadow-blue-200",
      notice: "bg-gradient-to-r from-indigo-500 to-indigo-600 text-white border-l-4 border-indigo-700 shadow-indigo-200",
      alert: "bg-gradient-to-r from-red-500 to-red-600 text-white border-l-4 border-red-700 shadow-red-200"
    }
    
    const baseStyles = "px-6 py-4 rounded-lg shadow-lg backdrop-blur-sm"
    const responsiveStyles = "max-w-md min-w-80 sm:max-w-sm sm:min-w-72"
    const typeSpecificStyles = typeStyles[this.typeValue] || typeStyles["info"]
    
    this.element.className += ` ${baseStyles} ${responsiveStyles} ${typeSpecificStyles}`
    
    // Ensure text is visible by setting explicit text color
    this.element.style.color = 'white'
    
    // Ensure content has proper text color
    const content = this.element.querySelector('.flash-content')
    if (content) {
      content.style.color = 'white'
      content.style.fontSize = '14px'
      content.style.fontWeight = '500'
    }
  }

  animateEntrance() {
    // Set initial state for entrance animation
    this.element.style.opacity = '0'
    this.element.style.transform = 'translateY(-20px) scale(0.95)'
    
    // Trigger entrance animation
    requestAnimationFrame(() => {
      this.element.style.opacity = '1'
      this.element.style.transform = 'translateY(0) scale(1)'
    })
  }



  addDismissButton() {
    const dismissButton = document.createElement("button")
    dismissButton.innerHTML = `
      <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
    `
    dismissButton.className = "absolute top-2 right-2 p-1 hover:bg-black hover:bg-opacity-10 rounded-full transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-white focus:ring-opacity-50"
    dismissButton.setAttribute('aria-label', 'Dismiss notification')
    dismissButton.addEventListener("click", () => this.dismiss())
    
    // Make the flash message container relative for absolute positioning
    this.element.style.position = 'relative'
    this.element.appendChild(dismissButton)
  }



  startAutoHide() {
    if (this.durationValue > 0) {
      this.autoHideTimeout = setTimeout(() => {
        this.dismiss()
      }, this.durationValue)
    }
  }

  dismiss() {
    this.pauseAutoHide()
    
    this.element.style.transition = "all 0.3s ease-out"
    
    if (this.positionValue.includes("right")) {
      this.element.style.transform = "translateX(100%) scale(0.95)"
    } else if (this.positionValue.includes("left")) {
      this.element.style.transform = "translateX(-100%) scale(0.95)"
    } else {
      this.element.style.opacity = "0"
      this.element.style.transform = "translateY(-20px) scale(0.95)"
    }
    
    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.remove()
      }
    }, 300)
  }

  pauseAutoHide() {
    if (this.autoHideTimeout) {
      clearTimeout(this.autoHideTimeout)
      this.autoHideTimeout = null
    }
  }

  resumeAutoHide() {
    if (!this.autoHideTimeout && this.durationValue > 0) {
      this.startAutoHide()
    }
  }



  disconnect() {
    this.pauseAutoHide()
  }
}

// Add CSS for animations
const style = document.createElement('style')
style.textContent = `
  .flash-message {
    max-width: 400px;
    min-width: 300px;
    backdrop-filter: blur(10px);
  }
  
  .flash-enter {
    transform: translateX(0) translateY(0) !important;
    opacity: 1 !important;
    scale: 1 !important;
  }
  
  @media (max-width: 640px) {
    .flash-message {
      max-width: calc(100vw - 2rem);
      min-width: auto;
    }
  }
`
document.head.appendChild(style);
