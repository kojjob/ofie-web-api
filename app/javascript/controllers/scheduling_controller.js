
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "timeSlotOption",
    "timeSlotRadio",
    "viewingTypeOption",
    "viewingTypeRadio",
    "viewingTypeIndicator"
  ]

  connect() {
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Close modal when clicking outside
    this.modalTarget.addEventListener('click', (e) => {
      if (e.target === this.modalTarget) {
        this.closeModal()
      }
    })

    // Close modal with Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !this.modalTarget.classList.contains('hidden')) {
        this.closeModal()
      }
    })
  }

  openModal() {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
    
    // Focus first input for accessibility
    const firstInput = this.modalTarget.querySelector('input[type="date"]')
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 100)
    }
  }

  closeModal() {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = 'auto'
  }

  selectTimeSlot(event) {
    const clickedOption = event.currentTarget
    const radioButton = clickedOption.querySelector('.time-slot-radio')
    
    // Remove selected state from all time slot options
    this.timeSlotOptionTargets.forEach(option => {
      option.classList.remove('border-blue-500', 'bg-blue-50')
      const border = option.querySelector('.time-slot-border')
      if (border) {
        border.classList.remove('border-blue-500')
      }
    })
    
    // Add selected state to clicked option
    clickedOption.classList.add('border-blue-500', 'bg-blue-50')
    const border = clickedOption.querySelector('.time-slot-border')
    if (border) {
      border.classList.add('border-blue-500')
    }
    
    // Check the radio button
    radioButton.checked = true
    
    // Dispatch custom event for form validation
    this.element.dispatchEvent(new CustomEvent('timeSlotSelected', {
      detail: { value: radioButton.value }
    }))
  }

  selectViewingType(event) {
    const clickedOption = event.currentTarget
    const radioButton = clickedOption.querySelector('.viewing-type-radio')
    const value = clickedOption.dataset.value
    
    // Remove selected state from all viewing type options
    this.viewingTypeOptionTargets.forEach(option => {
      option.classList.remove('border-blue-500', 'bg-blue-50')
      const indicator = option.querySelector('.viewing-type-indicator')
      const dot = indicator.querySelector('div')
      
      indicator.classList.remove('border-blue-600')
      indicator.classList.add('border-gray-300')
      dot.classList.add('hidden', 'bg-gray-300')
      dot.classList.remove('bg-blue-600')
    })
    
    // Add selected state to clicked option
    clickedOption.classList.add('border-blue-500', 'bg-blue-50')
    const indicator = clickedOption.querySelector('.viewing-type-indicator')
    const dot = indicator.querySelector('div')
    
    indicator.classList.add('border-blue-600')
    indicator.classList.remove('border-gray-300')
    dot.classList.remove('hidden', 'bg-gray-300')
    dot.classList.add('bg-blue-600')
    
    // Check the radio button
    radioButton.checked = true
    
    // Dispatch custom event for form validation
    this.element.dispatchEvent(new CustomEvent('viewingTypeSelected', {
      detail: { value: radioButton.value }
    }))
  }

  validateForm(event) {
    const form = event.target
    const requiredFields = form.querySelectorAll('[required]')
    let isValid = true
    
    requiredFields.forEach(field => {
      if (!field.value.trim()) {
        this.showFieldError(field, 'This field is required')
        isValid = false
      } else {
        this.clearFieldError(field)
      }
    })
    
    // Check if time slot is selected
    const timeSlotSelected = form.querySelector('input[name*="time_slot"]:checked')
    if (!timeSlotSelected) {
      this.showFormError('Please select a preferred time slot')
      isValid = false
    }
    
    if (!isValid) {
      event.preventDefault()
    }
  }

  showFieldError(field, message) {
    this.clearFieldError(field)
    
    field.classList.add('border-red-500', 'focus:ring-red-500')
    field.classList.remove('border-gray-300', 'focus:ring-blue-500')
    
    const errorDiv = document.createElement('div')
    errorDiv.className = 'text-red-500 text-sm mt-1 field-error'
    errorDiv.textContent = message
    
    field.parentNode.appendChild(errorDiv)
  }

  clearFieldError(field) {
    field.classList.remove('border-red-500', 'focus:ring-red-500')
    field.classList.add('border-gray-300', 'focus:ring-blue-500')
    
    const existingError = field.parentNode.querySelector('.field-error')
    if (existingError) {
      existingError.remove()
    }
  }

  showFormError(message) {
    // Remove existing error
    const existingError = this.modalTarget.querySelector('.form-error')
    if (existingError) {
      existingError.remove()
    }
    
    // Add new error
    const errorDiv = document.createElement('div')
    errorDiv.className = 'bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4 form-error'
    errorDiv.textContent = message
    
    const modalBody = this.modalTarget.querySelector('.modal-body')
    modalBody.insertBefore(errorDiv, modalBody.firstChild)
  }

  // Handle successful form submission
  handleSuccess() {
    this.closeModal()
    
    // Show success message
    const successDiv = document.createElement('div')
    successDiv.className = 'fixed top-4 right-4 bg-green-50 border border-green-200 text-green-700 px-6 py-4 rounded-lg shadow-lg z-50'
    successDiv.innerHTML = `
      <div class="flex items-center">
        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
        </svg>
        <span>Viewing request submitted successfully!</span>
      </div>
    `
    
    document.body.appendChild(successDiv)
    
    // Remove success message after 5 seconds
    setTimeout(() => {
      successDiv.remove()
    }, 5000)
  }
}