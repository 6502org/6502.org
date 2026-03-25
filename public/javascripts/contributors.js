// Sliding window effect for the contributors grid on the About page.
// The page renders 100 shuffled avatars (50 visible, 50 hidden).
// Every few seconds, the visible window shifts by one position,
// creating the appearance of avatars scrolling through the grid.

(function() {
  var grid = document.querySelector('.contributors-grid');
  if (!grid) return;

  // Snapshot all 100 images into a circular buffer
  var all = Array.prototype.slice.call(grid.querySelectorAll('img'));
  var pool = [];
  for (var i = 0; i < all.length; i++) {
    pool.push({ src: all[i].src, alt: all[i].alt, title: all[i].title });
  }

  // Collect the 50 visible img elements (the ones we'll update)
  var visible = [];
  for (var i = 0; i < all.length; i++) {
    if (!all[i].classList.contains('contributor-hidden')) visible.push(all[i]);
  }

  // Slide the window: decrement offset to bring a new avatar
  // into the top-left and shift everything else to the right
  var offset = 0;

  setInterval(function() {
    offset = (offset + pool.length - 1) % pool.length;

    for (var i = 0; i < visible.length; i++) {
      var di = (offset + i) % pool.length;
      visible[i].src = pool[di].src;
      visible[i].alt = pool[di].alt;
      visible[i].title = pool[di].title;
    }
  }, 3000);
})();
