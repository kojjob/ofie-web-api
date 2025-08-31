// Mobile Menu Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"];

  connect() {
    console.log("Mobile menu controller connected")
    this.isOpen = false;
    this.setupKeyboardNavigation();
    this.setupOutsideClickListener();
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
    console.log("Opening mobile menu")

    this.menuTarget.classList.remove('hidden');
    this.element.setAttribute('aria-expanded', 'true');
    this.isOpen = true;

    // Add smooth animation
    setTimeout(() => {
      this.menuTarget.classList.add('translate-x-0');
      this.menuTarget.classList.remove('translate-x-full');
    }, 10);

    // Switch icons
    if (this.hasOpenIconTarget) this.openIconTarget.classList.add('hidden');
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove('hidden');

    // Prevent body scroll when menu is open
    document.body.style.overflow = 'hidden';

    // Focus first menu item
    const firstMenuItem = this.menuTarget.querySelector('a');
    if (firstMenuItem) {
      setTimeout(() => firstMenuItem.focus(), 100);
    }
  }

  close() {
    console.log("Closing mobile menu")

    // Add smooth animation
    this.menuTarget.classList.add('translate-x-full');
    this.menuTarget.classList.remove('translate-x-0');

    this.element.setAttribute('aria-expanded', 'false');
    this.isOpen = false;

    // Switch icons back
    if (this.hasOpenIconTarget) this.openIconTarget.classList.remove('hidden');
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add('hidden');

    // Hide menu after animation completes
    setTimeout(() => {
      this.menuTarget.classList.add('hidden');
    }, 300);

    // Restore body scroll
    document.body.style.overflow = '';

    // Return focus to toggle button
    this.element.focus();
  }

  setupKeyboardNavigation() {
    this.boundKeydownHandler = (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        this.close();
      }
    };
    document.addEventListener('keydown', this.boundKeydownHandler);
  }

  setupOutsideClickListener() {
    this.boundClickHandler = (event) => {
      if (this.isOpen && !this.element.contains(event.target)) {
        this.close();
      }
    };
    document.addEventListener('click', this.boundClickHandler);
  }

  // Close menu when clicking on a link
  linkClicked(event) {
    console.log("Mobile menu link clicked")

    // Small delay to allow navigation to start
    setTimeout(() => {
      this.close()
    }, 100)
  }

  // Clean up event listeners
  disconnect() {
    document.body.style.overflow = '';

    if (this.boundKeydownHandler) {
      document.removeEventListener('keydown', this.boundKeydownHandler);
    }

    if (this.boundClickHandler) {
      document.removeEventListener('click', this.boundClickHandler);
    }
  }
};
