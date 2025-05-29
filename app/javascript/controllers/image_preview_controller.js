import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="image-preview"
export default class extends Controller {
  static targets = ["container", "grid"]

  connect() {
    console.log("Image preview controller connected")
  }

  preview(event) {
    const files = event.target.files
    
    if (files.length === 0) {
      this.containerTarget.classList.add("hidden")
      return
    }

    // Clear previous previews
    this.gridTarget.innerHTML = ""
    
    // Show container
    this.containerTarget.classList.remove("hidden")

    // Process each file
    Array.from(files).forEach((file, index) => {
      if (file.type.startsWith("image/")) {
        this.createPreview(file, index)
      }
    })
  }

  createPreview(file, index) {
    const reader = new FileReader()
    
    reader.onload = (e) => {
      const previewDiv = document.createElement("div")
      previewDiv.className = "relative group"
      
      const img = document.createElement("img")
      img.src = e.target.result
      img.className = "w-full h-32 object-cover rounded-lg"
      img.alt = `Preview ${index + 1}`
      
      const overlay = document.createElement("div")
      overlay.className = "absolute inset-0 bg-black bg-opacity-50 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex items-center justify-center"
      
      const fileName = document.createElement("span")
      fileName.className = "text-white text-xs text-center px-2"
      fileName.textContent = file.name.length > 20 ? file.name.substring(0, 20) + "..." : file.name
      
      overlay.appendChild(fileName)
      previewDiv.appendChild(img)
      previewDiv.appendChild(overlay)
      
      this.gridTarget.appendChild(previewDiv)
    }
    
    reader.readAsDataURL(file)
  }
}