// Enhanced Navbar Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static classes = ["scrolled"];
  static targets = ["menu"];

  connect() {
    this.setupScrollHandler();
    this.setupClickOutside();
  }

  disconnect() {
    this.teardownScrollHandler();
    this.teardownClickOutside();
  }

  setupScrollHandler() {
    this.handleScroll = this.handleScroll.bind(this);
    window.addEventListener("scroll", this.handleScroll, { passive: true });
  }

  teardownScrollHandler() {
    window.removeEventListener("scroll", this.handleScroll);
  }

  handleScroll() {
    const scrolled = window.scrollY > 20;
    
    if (scrolled && !this.element.classList.contains(this.scrolledClass)) {
      this.element.classList.add(this.scrolledClass);
    } else if (!scrolled && this.element.classList.contains(this.scrolledClass)) {
      this.element.classList.remove(this.scrolledClass);
    }
  }

  setupClickOutside() {
    this.handleClickOutside = this.handleClickOutside.bind(this);
    document.addEventListener("click", this.handleClickOutside);
  }

  teardownClickOutside() {
    document.removeEventListener("click", this.handleClickOutside);
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      // Close any open dropdowns
      const openDropdowns = this.element.querySelectorAll('[data-dropdown-target="menu"]:not(.hidden)');
      openDropdowns.forEach(dropdown => {
        dropdown.classList.add('hidden');
        const button = dropdown.previousElementSibling;
        if (button) {
          button.setAttribute('aria-expanded', 'false');
        }
      });
    }
  }
};
