import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["button", "content"]
  static values = { activeTab: String }

  connect() {
    // Set the first tab as active by default if no active tab is specified
    if (!this.activeTabValue && this.buttonTargets.length > 0) {
      this.activeTabValue = this.buttonTargets[0].dataset.tab
    }
    this.showActiveTab()
  }

  switch(event) {
    event.preventDefault()
    const clickedButton = event.currentTarget
    const targetTab = clickedButton.dataset.tab
    
    this.activeTabValue = targetTab
    this.showActiveTab()
  }

  showActiveTab() {
    // Remove active classes from all buttons
    this.buttonTargets.forEach(button => {
      button.classList.remove('active', 'border-blue-500', 'text-blue-600')
      button.classList.add('border-transparent', 'text-gray-500')
    })

    // Add active classes to the active button
    const activeButton = this.buttonTargets.find(button => button.dataset.tab === this.activeTabValue)
    if (activeButton) {
      activeButton.classList.add('active', 'border-blue-500', 'text-blue-600')
      activeButton.classList.remove('border-transparent', 'text-gray-500')
    }

    // Hide all tab contents
    this.contentTargets.forEach(content => {
      content.classList.add('hidden')
    })

    // Show the active tab content
    const activeContent = this.contentTargets.find(content => content.id === `${this.activeTabValue}-tab`)
    if (activeContent) {
      activeContent.classList.remove('hidden')
    }
  }
};
