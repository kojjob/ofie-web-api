import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gallery"
export default class extends Controller {
  static targets = ["mainImage", "thumbnail"]

  connect() {
    console.log("Gallery controller connected")
  }

  changeMainImage(event) {
    const clickedThumbnail = event.currentTarget
    const newImageUrl = clickedThumbnail.dataset.imageUrl
    const mainImage = this.mainImageTarget
    
    // Update the main image source
    mainImage.src = newImageUrl
    
    // Optional: Add a smooth transition effect
    mainImage.style.opacity = '0.5'
    
    // Reset opacity after image loads
    mainImage.onload = () => {
      mainImage.style.opacity = '1'
    }
    
    // Add visual feedback to show which thumbnail is active
    this.updateThumbnailSelection(clickedThumbnail)
  }
  
  updateThumbnailSelection(activeThumbnail) {
    // Remove active state from all thumbnails
    this.thumbnailTargets.forEach(thumbnail => {
      thumbnail.classList.remove('ring-2', 'ring-blue-500', 'ring-offset-2')
      thumbnail.classList.add('hover:opacity-80')
    })
    
    // Add active state to clicked thumbnail
    activeThumbnail.classList.add('ring-2', 'ring-blue-500', 'ring-offset-2')
    activeThumbnail.classList.remove('hover:opacity-80')
  }
}