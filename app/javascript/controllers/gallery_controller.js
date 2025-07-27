import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gallery"
export default class extends Controller {
  static targets = ["slide", "thumbnail", "counter", "fullscreenModal", "fullscreenSlide", "fullscreenCounter"]
  static values = { 
    currentIndex: Number,
    autoPlay: { type: Boolean, default: false },
    autoPlayInterval: { type: Number, default: 5000 }
  }

  connect() {
    console.log("Gallery controller connected")
    this.currentIndexValue = 0
    this.totalSlides = this.slideTargets.length
    this.autoPlayTimer = null
    
    console.log(`Found ${this.thumbnailTargets.length} thumbnail targets`)
    console.log(`Found ${this.slideTargets.length} slide targets`)
    
    // Initialize the gallery
    this.updateDisplay()
    this.setupKeyboardNavigation()
    
    // Start auto-play if enabled
    if (this.autoPlayValue && this.totalSlides > 1) {
      this.startAutoPlay()
    }
  }

  disconnect() {
    this.stopAutoPlay()
    this.removeKeyboardNavigation()
  }

  // Navigation methods
  nextSlide() {
    if (this.totalSlides <= 1) return
    
    this.currentIndexValue = (this.currentIndexValue + 1) % this.totalSlides
    this.updateDisplay()
    this.resetAutoPlay()
  }

  previousSlide() {
    if (this.totalSlides <= 1) return
    
    this.currentIndexValue = this.currentIndexValue === 0 
      ? this.totalSlides - 1 
      : this.currentIndexValue - 1
    this.updateDisplay()
    this.resetAutoPlay()
  }

  goToSlide(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const slideIndex = parseInt(event.currentTarget.dataset.slideIndex)
    console.log(`Thumbnail clicked - going to slide ${slideIndex}`)
    
    if (slideIndex >= 0 && slideIndex < this.totalSlides) {
      this.currentIndexValue = slideIndex
      this.updateDisplay()
      this.resetAutoPlay()
    }
  }

  // Display updates
  updateDisplay() {
    this.updateSlides()
    this.updateThumbnails()
    this.updateCounter()
    
    // Update fullscreen if it's open
    if (this.hasFullscreenModalTarget && !this.fullscreenModalTarget.classList.contains('hidden')) {
      this.updateFullscreenDisplay()
    }
  }

  updateSlides() {
    console.log(`Updating slides to show slide ${this.currentIndexValue}`)
    
    this.slideTargets.forEach((slide, index) => {
      if (index === this.currentIndexValue) {
        slide.classList.remove('hidden')
        slide.classList.add('block')
        console.log(`Showing slide ${index}`)
      } else {
        slide.classList.remove('block')
        slide.classList.add('hidden')
      }
    })
  }

  updateThumbnails() {
    if (!this.hasThumbnailTarget) return
    
    console.log(`Updating thumbnails - active: ${this.currentIndexValue}`)
    
    this.thumbnailTargets.forEach((thumbnail, index) => {
      // Remove all selection states
      thumbnail.classList.remove(
        'border-blue-500', 'border-gray-300', 'border-gray-400', 'ring-2', 'ring-blue-200'
      )
      
      // Apply appropriate state
      if (index === this.currentIndexValue) {
        thumbnail.classList.add('border-blue-500', 'ring-2', 'ring-blue-200')
        console.log(`Thumbnail ${index} is now active`)
      } else {
        thumbnail.classList.add('border-gray-300')
      }
    })
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.currentIndexValue + 1
    }
  }

  // Auto-play functionality
  startAutoPlay() {
    if (this.totalSlides <= 1) return
    
    this.autoPlayTimer = setInterval(() => {
      this.nextSlide()
    }, this.autoPlayIntervalValue)
  }

  stopAutoPlay() {
    if (this.autoPlayTimer) {
      clearInterval(this.autoPlayTimer)
      this.autoPlayTimer = null
    }
  }

  resetAutoPlay() {
    if (this.autoPlayValue) {
      this.stopAutoPlay()
      this.startAutoPlay()
    }
  }

  // Pause auto-play on hover
  pauseAutoPlay() {
    this.stopAutoPlay()
  }

  resumeAutoPlay() {
    if (this.autoPlayValue) {
      this.startAutoPlay()
    }
  }

  // Keyboard navigation
  setupKeyboardNavigation() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.keydownHandler)
  }

  removeKeyboardNavigation() {
    if (this.keydownHandler) {
      document.removeEventListener('keydown', this.keydownHandler)
    }
  }

  handleKeydown(event) {
    // Only handle keyboard events when gallery is visible
    if (!this.element.closest('body')) return
    
    switch(event.key) {
      case 'ArrowLeft':
        event.preventDefault()
        this.previousSlide()
        break
      case 'ArrowRight':
        event.preventDefault()
        this.nextSlide()
        break
      case 'Escape':
        this.closeFullscreen()
        break
      case 'f':
      case 'F':
        if (this.hasFullscreenModalTarget) {
          this.openFullscreen()
        }
        break
    }
  }

  // Fullscreen functionality
  openFullscreen() {
    if (!this.hasFullscreenModalTarget) return
    
    this.fullscreenModalTarget.classList.remove('hidden')
    this.updateFullscreenDisplay()
    document.body.classList.add('overflow-hidden-body')
    this.stopAutoPlay()
  }

  closeFullscreen() {
    if (!this.hasFullscreenModalTarget) return
    
    this.fullscreenModalTarget.classList.add('hidden')
    document.body.classList.remove('overflow-hidden-body')
    
    if (this.autoPlayValue) {
      this.startAutoPlay()
    }
  }

  nextSlideFullscreen() {
    this.nextSlide()
  }

  previousSlideFullscreen() {
    this.previousSlide()
  }

  updateFullscreenDisplay() {
    if (!this.hasFullscreenSlideTarget) return
    
    this.fullscreenSlideTargets.forEach((slide, index) => {
      if (index === this.currentIndexValue) {
        slide.classList.remove('hidden')
        slide.classList.add('block')
      } else {
        slide.classList.remove('block')
        slide.classList.add('hidden')
      }
    })
    
    if (this.hasFullscreenCounterTarget) {
      this.fullscreenCounterTarget.textContent = this.currentIndexValue + 1
    }
  }

  handleFullscreenKeydown(event) {
    switch(event.key) {
      case 'ArrowLeft':
        event.preventDefault()
        this.previousSlideFullscreen()
        break
      case 'ArrowRight':
        event.preventDefault()
        this.nextSlideFullscreen()
        break
      case 'Escape':
        event.preventDefault()
        this.closeFullscreen()
        break
    }
  }

  // Value change handlers
  currentIndexValueChanged() {
    this.updateDisplay()
  }

  autoPlayValueChanged() {
    if (this.autoPlayValue) {
      this.startAutoPlay()
    } else {
      this.stopAutoPlay()
    }
  }

  // Utility methods
  get canNavigate() {
    return this.totalSlides > 1
  }

  get isFirstSlide() {
    return this.currentIndexValue === 0
  }

  get isLastSlide() {
    return this.currentIndexValue === this.totalSlides - 1
  }
}
