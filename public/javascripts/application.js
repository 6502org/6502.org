function toggleNavMenu() {
    var links = document.querySelector('.nav-links');
    if (links.className.indexOf('open') !== -1) {
        links.className = links.className.replace(' open', '');
    } else {
        links.className += ' open';
    }
}

function initNavToggle() {
    var btn = document.querySelector('.nav-toggle');
    if (btn) {
        btn.onclick = function() { toggleNavMenu(); };
    }
}

if (document.addEventListener) {
    document.addEventListener('DOMContentLoaded', initNavToggle);
} else {
    window.attachEvent('onload', initNavToggle);
}
