import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gallery"
export default class extends Controller {
  static targets = ["slide", "thumbnail", "counter"]
  static values = { currentIndex: Number }

  connect() {
    console.log("Gallery controller connected")
    this.currentIndexValue = 0
    this.totalSlides = this.slideTargets.length
    this.updateCounter()
  }

  nextSlide() {
    if (this.currentIndexValue < this.totalSlides - 1) {
      this.currentIndexValue++
    } else {
      this.currentIndexValue = 0 // Loop back to first slide
    }
    this.showSlide(this.currentIndexValue)
  }

  previousSlide() {
    if (this.currentIndexValue > 0) {
      this.currentIndexValue--
    } else {
      this.currentIndexValue = this.totalSlides - 1 // Loop to last slide
    }
    this.showSlide(this.currentIndexValue)
  }

  goToSlide(event) {
    const slideIndex = parseInt(event.currentTarget.dataset.slideIndex)
    this.currentIndexValue = slideIndex
    this.showSlide(slideIndex)
  }

  showSlide(index) {
    // Hide all slides
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove('hidden')
        slide.classList.add('block')
      } else {
        slide.classList.remove('block')
        slide.classList.add('hidden')
      }
    })

    // Update thumbnail selection
    this.updateThumbnailSelection(index)
    
    // Update counter
    this.updateCounter()
  }

  updateThumbnailSelection(activeIndex) {
    if (this.hasThumbnailTarget) {
      this.thumbnailTargets.forEach((thumbnail, index) => {
        // Remove all selection indicators
        thumbnail.classList.remove('ring-2', 'ring-blue-500', 'ring-offset-2', 'border-indigo-500', 'border-blue-500', 'shadow-indigo-500/25')

        // Add selection indicators to active thumbnail only
        if (index === activeIndex) {
          thumbnail.classList.add('ring-2', 'ring-blue-500', 'ring-offset-2')
          // Also add border classes for consistency with HTML
          thumbnail.classList.add('border-indigo-500', 'shadow-indigo-500/25')
        }
      })
    }
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.currentIndexValue + 1
    }
  }

  // Keyboard navigation
  keydown(event) {
    if (event.key === 'ArrowLeft') {
      this.previousSlide()
    } else if (event.key === 'ArrowRight') {
      this.nextSlide()
    }
  }
}