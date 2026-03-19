var GroupsFilter = {
    init: function() {
        var checkbox = document.querySelector('.groups-filter-checkbox');
        if (!checkbox) return;
        checkbox.onchange = function() {
            GroupsFilter.apply(this.checked);
        };
    },

    apply: function(exclusive) {
        var page = document.querySelector('.two-col-main');
        if (!page) return;

        // Filter list items
        var items = page.getElementsByTagName('li');
        for (var i = 0; i < items.length; i++) {
            if (exclusive && !items[i].hasAttribute('data-6502-exclusive')) {
                items[i].style.display = 'none';
            } else {
                items[i].style.display = '';
            }
        }

        // Hide empty sections
        var sections = page.getElementsByTagName('ul');
        for (var i = 0; i < sections.length; i++) {
            var hasVisible = false;
            var lis = sections[i].getElementsByTagName('li');
            for (var j = 0; j < lis.length; j++) {
                if (lis[j].style.display !== 'none') {
                    hasVisible = true;
                    break;
                }
            }
            sections[i].style.display = hasVisible ? '' : 'none';

            var prev = sections[i].previousElementSibling;
            while (prev && prev.className.indexOf('category-header') === -1) {
                prev = prev.previousElementSibling;
            }
            if (prev) {
                prev.style.display = hasVisible ? '' : 'none';
            }
        }
    }
};

if (document.addEventListener) {
    document.addEventListener('DOMContentLoaded', GroupsFilter.init);
} else {
    window.attachEvent('onload', GroupsFilter.init);
}
