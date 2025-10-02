// Test Gallery Functionality
// Paste this in your browser console on the property show page

console.log('=== Testing Gallery Functionality ===');

// Check if gallery elements exist
const gallery = document.querySelector('[data-controller="gallery"]');
const thumbnails = document.querySelectorAll('[data-gallery-target="thumbnail"]');
const slides = document.querySelectorAll('[data-gallery-target="slide"]');

console.log('Gallery found:', !!gallery);
console.log('Thumbnails found:', thumbnails.length);
console.log('Slides found:', slides.length);

// Check z-index values
const galleryZIndex = window.getComputedStyle(gallery).zIndex;
const firstThumbnail = thumbnails[0];
const thumbnailZIndex = firstThumbnail ? window.getComputedStyle(firstThumbnail).zIndex : 'none';

console.log('Gallery z-index:', galleryZIndex);
console.log('Thumbnail z-index:', thumbnailZIndex);

// Test thumbnail click
if (thumbnails.length > 1) {
  console.log('Testing thumbnail click...');
  
  // Click the second thumbnail
  thumbnails[1].click();
  
  setTimeout(() => {
    const visibleSlide = document.querySelector('[data-gallery-target="slide"]:not(.hidden)');
    const slideIndex = visibleSlide ? visibleSlide.getAttribute('data-slide-index') : 'none';
    console.log('Visible slide after click:', slideIndex);
    
    // Check if correct thumbnail is highlighted
    const activeThumbnail = document.querySelector('[data-gallery-target="thumbnail"].border-blue-500');
    const activeThumbnailIndex = activeThumbnail ? activeThumbnail.getAttribute('data-slide-index') : 'none';
    console.log('Active thumbnail index:', activeThumbnailIndex);
    
    console.log('✅ Test complete! Check console for results.');
  }, 200);
} else {
  console.log('⚠️ Not enough thumbnails to test click functionality');
}
