// Dropdown Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.isOpen = false;
    this.setupKeyboardNavigation();
    // Don't set up outside click listener here - only when opening
  }

  toggle(event) {
    event.preventDefault();
    event.stopPropagation();
    
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.menuTarget.classList.remove('hidden');
    this.element.querySelector('button').setAttribute('aria-expanded', 'true');
    this.isOpen = true;
    
    // Set up outside click listener when opening
    this.setupOutsideClickListener();
    
    // Focus first menu item
    const firstMenuItem = this.menuTarget.querySelector('a');
    if (firstMenuItem) {
      firstMenuItem.focus();
    }
  }

  close() {
    this.menuTarget.classList.add('hidden');
    this.element.querySelector('button').setAttribute('aria-expanded', 'false');
    this.isOpen = false;
    
    // Remove outside click listener when closing
    this.removeOutsideClickListener();
    
    // Return focus to button
    this.element.querySelector('button').focus();
  }

  setupKeyboardNavigation() {
    this.element.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        this.close();
      }

      if (event.key === 'ArrowDown' && !this.isOpen) {
        event.preventDefault();
        this.open();
      }

      if (this.isOpen && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
        event.preventDefault();
        this.navigateMenu(event.key === 'ArrowDown' ? 1 : -1);
      }
    });
  }

  setupOutsideClickListener() {
    // Create the click handler
    this.boundClickHandler = (event) => {
      // Check if click is outside the dropdown
      if (!this.element.contains(event.target)) {
        this.close();
      }
    };
    
    // Use setTimeout to avoid catching the opening click
    setTimeout(() => {
      document.addEventListener('click', this.boundClickHandler);
    }, 0);
  }
  
  removeOutsideClickListener() {
    if (this.boundClickHandler) {
      document.removeEventListener('click', this.boundClickHandler);
      this.boundClickHandler = null;
    }
  }

  disconnect() {
    this.removeOutsideClickListener();
  }

  navigateMenu(direction) {
    const menuItems = Array.from(this.menuTarget.querySelectorAll('a'));
    const currentIndex = menuItems.indexOf(document.activeElement);
    let nextIndex = currentIndex + direction;
    
    if (nextIndex < 0) nextIndex = menuItems.length - 1;
    if (nextIndex >= menuItems.length) nextIndex = 0;
    
    menuItems[nextIndex].focus();
  }
}
