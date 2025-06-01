import { Controller } from "@hotwired/stimulus"

// Enhanced Batch Upload Controller with better validation and UX
export default class extends Controller {
  static targets = [
    "dropZone", "fileInput", "uploadPrompt", "fileSelected", "fileName", 
    "uploadButton", "uploadProgress", "progressBar", "progressText", "uploadResults",
    "filePreview", "validationResults", "fileSize", "fileType"
  ]

  connect() {
    this.selectedFile = null
    this.maxFileSize = 10 * 1024 * 1024 // 10MB
    this.allowedTypes = ['.csv']
    this.setupEventListeners()
    this.initializeValidation()
  }

  setupEventListeners() {
    // Prevent default drag behaviors
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      this.dropZoneTarget.addEventListener(eventName, this.preventDefaults, false)
      document.body.addEventListener(eventName, this.preventDefaults, false)
    })
  }

  initializeValidation() {
    this.validationRules = [
      { rule: this.validateFileType.bind(this), message: 'File must be in CSV format' },
      { rule: this.validateFileSize.bind(this), message: 'File size must be less than 10MB' },
      { rule: this.validateFileContent.bind(this), message: 'File appears to be empty or corrupted' }
    ]
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  // ==================== ENHANCED DRAG & DROP ====================

  handleDragEnter(e) {
    this.dropZoneTarget.classList.add('border-blue-400', 'bg-blue-50')
    this.showDropZoneMessage('Drop CSV file here')
  }

  handleDragOver(e) {
    this.dropZoneTarget.classList.add('border-blue-400', 'bg-blue-50')
  }

  handleDragLeave(e) {
    // Only remove classes if we're leaving the drop zone entirely
    if (!this.dropZoneTarget.contains(e.relatedTarget)) {
      this.dropZoneTarget.classList.remove('border-blue-400', 'bg-blue-50')
      this.hideDropZoneMessage()
    }
  }

  handleDrop(e) {
    this.dropZoneTarget.classList.remove('border-blue-400', 'bg-blue-50')
    this.hideDropZoneMessage()
    
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

  // ==================== ENHANCED FILE VALIDATION ====================

  async handleFileSelection(file) {
    try {
      // Show loading state during validation
      this.showValidationLoading()
      
      // Run validation
      const validationResult = await this.validateFile(file)
      
      if (validationResult.isValid) {
        this.selectedFile = file
        await this.showFileSelected(file)
      } else {
        this.showValidationErrors(validationResult.errors)
      }
    } catch (error) {
      console.error('File validation error:', error)
      this.showError('Failed to validate file. Please try again.')
    }
  }

  async validateFile(file) {
    const errors = []
    
    for (const validation of this.validationRules) {
      try {
        const isValid = await validation.rule(file)
        if (!isValid) {
          errors.push(validation.message)
        }
      } catch (error) {
        errors.push(`Validation error: ${error.message}`)
      }
    }
    
    return {
      isValid: errors.length === 0,
      errors: errors
    }
  }

  validateFileType(file) {
    const extension = '.' + file.name.split('.').pop().toLowerCase()
    return this.allowedTypes.includes(extension)
  }

  validateFileSize(file) {
    return file.size <= this.maxFileSize
  }

  async validateFileContent(file) {
    return new Promise((resolve) => {
      if (file.size === 0) {
        resolve(false)
        return
      }
      
      const reader = new FileReader()
      reader.onload = (e) => {
        const content = e.target.result
        // Basic content validation - check if it has CSV-like structure
        const lines = content.split('\n').filter(line => line.trim().length > 0)
        const hasHeaders = lines.length > 0 && lines[0].includes(',')
        const hasData = lines.length > 1
        
        resolve(hasHeaders && hasData)
      }
      reader.onerror = () => resolve(false)
      
      // Read first 1KB to validate structure
      const chunk = file.slice(0, 1024)
      reader.readAsText(chunk)
    })
  }

  // ==================== ENHANCED FILE PREVIEW ====================

  async showFileSelected(file) {
    // Update file info
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = `${file.name}`
    }
    
    if (this.hasFileSizeTarget) {
      this.fileSizeTarget.textContent = this.formatFileSize(file.size)
    }
    
    if (this.hasFileTypeTarget) {
      this.fileTypeTarget.textContent = file.type || 'text/csv'
    }
    
    // Show file preview if available
    await this.generateFilePreview(file)
    
    // Show file selected state
    this.uploadPromptTarget.classList.add('hidden')
    this.fileSelectedTarget.classList.remove('hidden')
    
    if (this.hasValidationResultsTarget) {
      this.validationResultsTarget.classList.add('hidden')
    }
  }

  async generateFilePreview(file) {
    if (!this.hasFilePreviewTarget) return
    
    try {
      const reader = new FileReader()
      reader.onload = (e) => {
        const content = e.target.result
        const lines = content.split('\n').slice(0, 6) // First 5 lines + header
        
        let previewHTML = '<div class="text-xs bg-gray-50 rounded-lg p-3 mt-3">'
        previewHTML += '<h4 class="font-medium text-gray-900 mb-2">File Preview</h4>'
        previewHTML += '<div class="font-mono text-gray-700 space-y-1">'
        
        lines.forEach((line, index) => {
          if (line.trim()) {
            const lineClass = index === 0 ? 'font-semibold text-blue-600' : 'text-gray-600'
            const truncatedLine = line.length > 80 ? line.substring(0, 80) + '...' : line
            previewHTML += `<div class="${lineClass}">${this.escapeHtml(truncatedLine)}</div>`
          }
        })
        
        if (content.split('\n').length > 6) {
          previewHTML += '<div class="text-gray-400 italic">... and more rows</div>'
        }
        
        previewHTML += '</div></div>'
        
        this.filePreviewTarget.innerHTML = previewHTML
      }
      
      // Read first 2KB for preview
      const chunk = file.slice(0, 2048)
      reader.readAsText(chunk)
    } catch (error) {
      console.error('Preview generation error:', error)
      this.filePreviewTarget.innerHTML = '<div class="text-xs text-gray-500 mt-3">Preview not available</div>'
    }
  }

  // ==================== ENHANCED UPLOAD PROCESS ====================

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

      // Upload with progress tracking
      const response = await this.uploadWithProgress(formData)
      const data = await response.json()

      if (response.ok) {
        this.showUploadSuccess(data)
      } else {
        // Check if we need to redirect to login
        if (data.redirect_to) {
          window.location.href = data.redirect_to
          return
        }
        this.showUploadError(data.error || 'Upload failed')
      }

    } catch (error) {
      console.error('Upload error:', error)
      this.showUploadError('Network error occurred during upload')
    }
  }

  uploadWithProgress(formData) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()
      
      // Track upload progress
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) {
          const percentComplete = (e.loaded / e.total) * 100
          this.updateProgress(percentComplete, 'Uploading...')
        }
      })
      
      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          // Parse response as fetch-like object
          resolve({
            ok: true,
            status: xhr.status,
            json: () => Promise.resolve(JSON.parse(xhr.responseText))
          })
        } else {
          reject(new Error(`HTTP ${xhr.status}: ${xhr.statusText}`))
        }
      })
      
      xhr.addEventListener('error', () => {
        reject(new Error('Network error'))
      })
      
      xhr.open('POST', '/batch_properties/upload')
      xhr.setRequestHeader('Accept', 'application/json')
      xhr.setRequestHeader('X-CSRF-Token', this.getCSRFToken())
      xhr.send(formData)
    })
  }

  updateProgress(percentage, message) {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percentage}%`
    }
    
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${message} ${Math.round(percentage)}%`
    }
  }

  // ==================== UI STATE MANAGEMENT ====================

  showValidationLoading() {
    if (this.hasValidationResultsTarget) {
      this.validationResultsTarget.innerHTML = `
        <div class="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <div class="flex items-center">
            <div class="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600 mr-3"></div>
            <span class="text-blue-800 text-sm">Validating file...</span>
          </div>
        </div>
      `
      this.validationResultsTarget.classList.remove('hidden')
    }
  }

  showValidationErrors(errors) {
    if (this.hasValidationResultsTarget) {
      let errorHTML = `
        <div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
          <div class="flex items-start">
            <svg class="w-5 h-5 text-red-400 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
            </svg>
            <div>
              <h4 class="text-red-800 text-sm font-semibold">File Validation Failed</h4>
              <ul class="mt-2 text-red-700 text-sm space-y-1">
      `
      
      errors.forEach(error => {
        errorHTML += `<li>• ${error}</li>`
      })
      
      errorHTML += `
              </ul>
              <button type="button" 
                      class="mt-3 text-red-700 text-sm underline hover:text-red-900"
                      data-action="click->batch-upload#clearFile">
                Try Another File
              </button>
            </div>
          </div>
        </div>
      `
      
      this.validationResultsTarget.innerHTML = errorHTML
      this.validationResultsTarget.classList.remove('hidden')
    } else {
      // Fallback to alert
      alert('File validation failed:\n' + errors.join('\n'))
    }
  }

  clearFile() {
    this.selectedFile = null
    this.fileInputTarget.value = ''
    
    // Reset UI
    this.fileSelectedTarget.classList.add('hidden')
    this.uploadProgressTarget.classList.add('hidden')
    this.uploadResultsTarget.classList.add('hidden')
    this.uploadPromptTarget.classList.remove('hidden')
    
    if (this.hasValidationResultsTarget) {
      this.validationResultsTarget.classList.add('hidden')
    }
    
    if (this.hasFilePreviewTarget) {
      this.filePreviewTarget.innerHTML = ''
    }
  }

  showUploadProgress() {
    this.fileSelectedTarget.classList.add('hidden')
    this.uploadProgressTarget.classList.remove('hidden')
    
    // Reset progress
    this.updateProgress(0, 'Initializing...')
  }

  showUploadSuccess(data) {
    // Hide progress, show results
    this.uploadProgressTarget.classList.add('hidden')
    this.uploadResultsTarget.classList.remove('hidden')

    const summary = data.validation_summary
    const batchUpload = data.batch_upload

    this.uploadResultsTarget.innerHTML = `
      <div class="bg-green-50 border-2 border-green-200 rounded-2xl p-6">
        <div class="flex items-center mb-6">
          <div class="w-12 h-12 bg-green-500 rounded-full flex items-center justify-center">
            <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
          </div>
          <div class="ml-4">
            <h3 class="text-lg font-semibold text-green-800">Upload Successful!</h3>
            <p class="text-green-600">Your CSV file has been validated and is ready for processing</p>
          </div>
        </div>
        
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div class="text-center bg-white rounded-lg p-3">
            <div class="text-2xl font-bold text-gray-900">${summary.total}</div>
            <div class="text-sm text-gray-600">Total Properties</div>
          </div>
          <div class="text-center bg-white rounded-lg p-3">
            <div class="text-2xl font-bold text-green-600">${summary.valid}</div>
            <div class="text-sm text-gray-600">Valid</div>
          </div>
          <div class="text-center bg-white rounded-lg p-3">
            <div class="text-2xl font-bold text-red-600">${summary.invalid}</div>
            <div class="text-sm text-gray-600">Invalid</div>
          </div>
          <div class="text-center bg-white rounded-lg p-3">
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

  // ==================== UTILITY METHODS ====================

  showDropZoneMessage(message) {
    // Could add a temporary message overlay
  }

  hideDropZoneMessage() {
    // Hide any temporary message overlay
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
    // Enhanced error display
    console.error('Batch Upload Error:', message)
    
    // Could implement toast notifications here instead of alert
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

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}

// Make processProperties available globally for the dynamic button
window.processProperties = function(batchUploadId) {
  const controller = document.querySelector('[data-controller="batch-upload"]')
  if (controller && controller.batchUploadController) {
    controller.batchUploadController.processProperties(batchUploadId)
  }
}
