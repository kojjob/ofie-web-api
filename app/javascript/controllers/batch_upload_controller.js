import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dropZone", "fileInput", "uploadPrompt", "fileSelected", "fileName", 
    "uploadButton", "uploadProgress", "progressBar", "progressText", "uploadResults"
  ]

  connect() {
    this.selectedFile = null
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Prevent default drag behaviors
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      this.dropZoneTarget.addEventListener(eventName, this.preventDefaults, false)
      document.body.addEventListener(eventName, this.preventDefaults, false)
    })
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  handleDragEnter(e) {
    this.dropZoneTarget.classList.add('border-blue-400', 'bg-blue-50')
  }

  handleDragOver(e) {
    this.dropZoneTarget.classList.add('border-blue-400', 'bg-blue-50')
  }

  handleDragLeave(e) {
    this.dropZoneTarget.classList.remove('border-blue-400', 'bg-blue-50')
  }

  handleDrop(e) {
    this.dropZoneTarget.classList.remove('border-blue-400', 'bg-blue-50')
    
    const files = e.dataTransfer.files
    if (files.length > 0) {
      this.handleFileSelection(files[0])
    }
  }

  openFileDialog() {
    this.fileInputTarget.click()
  }

  handleFileSelect(e) {
    const file = e.target.files[0]
    if (file) {
      this.handleFileSelection(file)
    }
  }

  handleFileSelection(file) {
    // Validate file type
    if (!file.name.toLowerCase().endsWith('.csv')) {
      this.showError('Please select a CSV file')
      return
    }

    // Validate file size (10MB limit)
    const maxSize = 10 * 1024 * 1024 // 10MB in bytes
    if (file.size > maxSize) {
      this.showError('File size must be less than 10MB')
      return
    }

    this.selectedFile = file
    this.showFileSelected(file)
  }

  showFileSelected(file) {
    this.fileNameTarget.textContent = `${file.name} (${this.formatFileSize(file.size)})`
    
    // Hide upload prompt, show file selected
    this.uploadPromptTarget.classList.add('hidden')
    this.fileSelectedTarget.classList.remove('hidden')
  }

  clearFile() {
    this.selectedFile = null
    this.fileInputTarget.value = ''
    
    // Reset UI
    this.fileSelectedTarget.classList.add('hidden')
    this.uploadProgressTarget.classList.add('hidden')
    this.uploadResultsTarget.classList.add('hidden')
    this.uploadPromptTarget.classList.remove('hidden')
  }

  async uploadFile() {
    if (!this.selectedFile) {
      this.showError('Please select a file first')
      return
    }

    try {
      // Show upload progress
      this.showUploadProgress()

      // Create form data
      const formData = new FormData()
      formData.append('csv_file', this.selectedFile)
      formData.append('authenticity_token', this.getCSRFToken())

      // Upload file
      const response = await fetch('/batch_properties/upload', {
        method: 'POST',
        body: formData,
        credentials: 'same-origin'
      })

      const data = await response.json()

      if (response.ok) {
        this.showUploadSuccess(data)
      } else {
        this.showUploadError(data.error || 'Upload failed')
      }

    } catch (error) {
      console.error('Upload error:', error)
      this.showUploadError('Network error occurred during upload')
    }
  }

  showUploadProgress() {
    this.fileSelectedTarget.classList.add('hidden')
    this.uploadProgressTarget.classList.remove('hidden')
    
    // Simulate progress (since we don't have real progress tracking)
    let progress = 0
    const interval = setInterval(() => {
      progress += Math.random() * 15
      if (progress > 90) progress = 90
      
      this.progressBarTarget.style.width = `${progress}%`
      this.progressTextTarget.textContent = `Processing... ${Math.round(progress)}%`
      
      if (progress >= 90) {
        clearInterval(interval)
        this.progressTextTarget.textContent = 'Finalizing validation...'
      }
    }, 200)
    
    // Store interval for cleanup
    this.progressInterval = interval
  }

  showUploadSuccess(data) {
    // Clear progress interval
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
    }

    // Hide progress, show results
    this.uploadProgressTarget.classList.add('hidden')
    this.uploadResultsTarget.classList.remove('hidden')

    const summary = data.validation_summary
    const batchUpload = data.batch_upload

    this.uploadResultsTarget.innerHTML = `
      <div class="bg-green-50 border-2 border-green-200 rounded-2xl p-6">
        <div class="flex items-center mb-4">
          <div class="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
          </div>
          <div class="ml-4">
            <h3 class="text-lg font-semibold text-green-800">Upload Successful!</h3>
            <p class="text-green-600">Your CSV file has been validated and is ready for processing</p>
          </div>
        </div>
        
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div class="text-center">
            <div class="text-2xl font-bold text-gray-900">${summary.total}</div>
            <div class="text-sm text-gray-600">Total Properties</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-green-600">${summary.valid}</div>
            <div class="text-sm text-gray-600">Valid</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-red-600">${summary.invalid}</div>
            <div class="text-sm text-gray-600">Invalid</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-blue-600">${summary.success_rate}%</div>
            <div class="text-sm text-gray-600">Success Rate</div>
          </div>
        </div>
        
        <div class="flex flex-col sm:flex-row gap-4">
          <a href="/batch_properties/${batchUpload.id}/preview" 
             class="flex-1 bg-blue-600 text-white text-center px-6 py-3 rounded-xl font-medium hover:bg-blue-700 transition-colors duration-200">
            Preview Properties
          </a>
          
          ${summary.valid > 0 ? `
            <button onclick="this.processProperties('${batchUpload.id}')"
                    class="flex-1 bg-green-600 text-white px-6 py-3 rounded-xl font-medium hover:bg-green-700 transition-colors duration-200">
              Process ${summary.valid} Properties
            </button>
          ` : ''}
          
          <button onclick="location.reload()" 
                  class="bg-gray-200 text-gray-700 px-6 py-3 rounded-xl font-medium hover:bg-gray-300 transition-colors duration-200">
            Upload Another File
          </button>
        </div>
      </div>
    `
  }

  showUploadError(errorMessage) {
    // Clear progress interval
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
    }

    // Hide progress, show results
    this.uploadProgressTarget.classList.add('hidden')
    this.uploadResultsTarget.classList.remove('hidden')

    this.uploadResultsTarget.innerHTML = `
      <div class="bg-red-50 border-2 border-red-200 rounded-2xl p-6">
        <div class="flex items-center mb-4">
          <div class="w-10 h-10 bg-red-500 rounded-full flex items-center justify-center">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </div>
          <div class="ml-4">
            <h3 class="text-lg font-semibold text-red-800">Upload Failed</h3>
            <p class="text-red-600">${errorMessage}</p>
          </div>
        </div>
        
        <div class="flex gap-4">
          <button onclick="location.reload()" 
                  class="bg-blue-600 text-white px-6 py-3 rounded-xl font-medium hover:bg-blue-700 transition-colors duration-200">
            Try Again
          </button>
          
          <a href="/batch_properties/template.csv" 
             class="bg-gray-200 text-gray-700 px-6 py-3 rounded-xl font-medium hover:bg-gray-300 transition-colors duration-200">
            Download Template
          </a>
        </div>
      </div>
    `
  }

  async processProperties(batchUploadId) {
    try {
      const response = await fetch(`/batch_properties/${batchUploadId}/process_batch`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        credentials: 'same-origin'
      })

      const data = await response.json()

      if (response.ok) {
        // Redirect to batch properties index to monitor progress
        window.location.href = '/batch_properties'
      } else {
        this.showError(data.error || 'Failed to start processing')
      }

    } catch (error) {
      console.error('Processing error:', error)
      this.showError('Network error occurred while starting processing')
    }
  }

  showError(message) {
    // Simple error display - could be enhanced with a toast notification
    alert(`Error: ${message}`)
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  }
}

// Make processProperties available globally for the dynamic button
window.processProperties = function(batchUploadId) {
  const controller = document.querySelector('[data-controller="batch-upload"]')
  if (controller && controller.batchUploadController) {
    controller.batchUploadController.processProperties(batchUploadId)
  }
}
