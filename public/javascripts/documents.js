// Find the closest ancestor matching a CSS selector.
// Built-in on modern browsers but not on older ones like IE 11.
function closestAncestor(el, selector) {
    while (el && el.nodeType === 1) {
        if (el.matches ? el.matches(selector) : el.msMatchesSelector(selector)) {
            return el;
        }
        el = el.parentElement;
    }
    return null;
}

function showOlderVersions(link) {
    var item = closestAncestor(link, '.doc-item');
    var topBefore = item.getBoundingClientRect().top;

    item.className += ' doc-highlight';

    var prev = item.previousElementSibling;
    while (prev && prev.className.indexOf('doc-obsolete') !== -1) {
        prev.style.display = 'block';
        prev.className += ' doc-highlight';
        prev = prev.previousElementSibling;
    }

    link.style.display = 'none';

    // Keep the clicked item in the same viewport position.
    var topAfter = item.getBoundingClientRect().top;
    window.scrollBy(0, topAfter - topBefore);
}

// Attach click handlers to all older version links.
function initOlderVersionLinks() {
    var links = document.getElementsByClassName('doc-older-link');
    for (var i = 0; i < links.length; i++) {
        links[i].onclick = function(e) {
            e.preventDefault();
            showOlderVersions(this);
        };
    }
}

if (document.addEventListener) {
    document.addEventListener('DOMContentLoaded', initOlderVersionLinks);
} else {
    window.attachEvent('onload', initOlderVersionLinks);
}
