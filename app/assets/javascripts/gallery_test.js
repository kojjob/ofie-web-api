// Gallery Test Helper
// Add this to browser console to test gallery functionality

function testGallery() {
  const galleryController = document.querySelector('[data-controller="gallery"]');
  const thumbnails = document.querySelectorAll('[data-gallery-target="thumbnail"]');
  const slides = document.querySelectorAll('[data-gallery-target="slide"]');
  
  console.log('=== Gallery Test Results ===');
  console.log(`Gallery element found: ${!!galleryController}`);
  console.log(`Thumbnails found: ${thumbnails.length}`);
  console.log(`Slides found: ${slides.length}`);
  
  // Test thumbnail clicks
  thumbnails.forEach((thumbnail, index) => {
    console.log(`Thumbnail ${index}:`, {
      hasDataAction: !!thumbnail.getAttribute('data-action'),
      hasSlideIndex: !!thumbnail.getAttribute('data-slide-index'),
      slideIndex: thumbnail.getAttribute('data-slide-index')
    });
  });
  
  // Test manual slide change
  if (thumbnails.length > 1) {
    console.log('Testing thumbnail click...');
    thumbnails[1].click();
    
    setTimeout(() => {
      const activeSlide = document.querySelector('[data-gallery-target="slide"].block');
      const slideIndex = activeSlide ? activeSlide.getAttribute('data-slide-index') : 'none';
      console.log(`Active slide after click: ${slideIndex}`);
    }, 100);
  }
}

// Run test
testGallery();
