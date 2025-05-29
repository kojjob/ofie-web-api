// Mobile Menu Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.isOpen = false;
    this.setupKeyboardNavigation();
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
    this.menuTarget.classList.remove('hidden');
    this.element.setAttribute('aria-expanded', 'true');
    this.isOpen = true;
    
    // Prevent body scroll when menu is open
    document.body.style.overflow = 'hidden';
    
    // Focus first menu item
    const firstMenuItem = this.menuTarget.querySelector('a');
    if (firstMenuItem) {
      setTimeout(() => firstMenuItem.focus(), 100);
    }
  }

  close() {
    this.menuTarget.classList.add('hidden');
    this.element.setAttribute('aria-expanded', 'false');
    this.isOpen = false;
    
    // Restore body scroll
    document.body.style.overflow = '';
    
    // Return focus to toggle button
    this.element.focus();
  }

  setupKeyboardNavigation() {
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        this.close();
      }
    });
  }

  // Close menu when clicking outside
  disconnect() {
    document.body.style.overflow = '';
  }
}
