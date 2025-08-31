import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="image-gallery"
export default class extends Controller {
  static targets = ["mainImage"]

  connect() {
    console.log("Image gallery controller connected")
  }

  selectImage(event) {
    const imageUrl = event.currentTarget.dataset.imageUrl
    const mainImage = this.mainImageTarget
    
    if (imageUrl && mainImage) {
      mainImage.src = imageUrl
      
      // Add fade effect
      mainImage.style.opacity = "0.5"
      setTimeout(() => {
        mainImage.style.opacity = "1"
      }, 150)
    }
  }
};
