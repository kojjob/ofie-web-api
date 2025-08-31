// Mobile Search Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["searchBar"];

  connect() {
    this.isOpen = false;
  }

  toggle(event) {
    event.preventDefault();
    
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.searchBarTarget.classList.remove('hidden');
    this.isOpen = true;
    
    // Focus the search input
    const searchInput = this.searchBarTarget.querySelector('input');
    if (searchInput) {
      setTimeout(() => searchInput.focus(), 100);
    }
  }

  close() {
    this.searchBarTarget.classList.add('hidden');
    this.isOpen = false;
  }

  // Close search when clicking outside
  disconnect() {
    document.removeEventListener('click', this.handleClickOutside);
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target) && this.isOpen) {
      this.close();
    }
  }
};
