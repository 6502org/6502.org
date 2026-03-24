<?php

class ApplicationHelper extends Mad_View_Helper_Base
{
    public function isProduction()
    {
        return MAD_ENV == 'production';
    }

    public function isHomePage()
    {
        return $this->controller->getControllerName() == 'contents'
            && $this->controller->getActionName() == 'home';
    }

    public function milestoneYears()
    {
        $foundedYear = 1999;
        $foundedMonth = 4; // domain registered 1999-04-20
        $now = getdate();
        $years = $now['year'] - $foundedYear;
        if ($now['mon'] < $foundedMonth) {
            $years--;
        }
        return floor($years / 5) * 5;
    }
    public function navLink($label, $urlOptions)
    {
        $controller = $this->controller->getControllerName();
        $action = $this->controller->getActionName();

        if (is_array($urlOptions)) {
            $active = ($controller == $urlOptions['controller'])
                && (!isset($urlOptions['action']) || $action == $urlOptions['action']);
        } else {
            $active = false;
        }

        return $this->linkTo($label, $urlOptions,
            $active ? ['class' => 'nav-active'] : []);
    }

    /**
     * Renders a category header and registers it for the sidebar.
     *
     *   <?= $this->categoryHeader('games', 'Games') ?>
     */
    protected $categories = [];

    public function categoryHeader($anchor, $title, $shortTitle = null)
    {
        foreach ($this->categories as $category) {
            if ($category['anchor'] === $anchor) {
                throw new Exception("Duplicate category anchor: $anchor");
            }
        }
        $this->categories[] = ['anchor' => $anchor, 'title' => $shortTitle ? $shortTitle : $title];

        return '<p class="category-header"><img src="/images/files/folder_open.gif" alt="**">&nbsp;'
             . '<a name="' . $this->h($anchor) . '"><b>' . $this->h($title) . '</b></a>';
    }

    /**
     * Renders the categories sidebar box from accumulated categoryHeader() calls.
     */
    public function categoriesSidebar()
    {
        if (empty($this->categories)) { return ''; }

        $html = '<div class="sidebar-box">'
              . '<div class="boxtitle">Categories</div>'
              . '<ul class="box sidebar-list">';

        foreach ($this->categories as $category) {
            $html .= '<li><a href="#' . $this->h($category['anchor']) . '">'
                   . $this->h($category['title']) . '</a></li>';
        }

        $html .= '</ul></div>';
        $this->categories = [];
        return $html;
    }

    public function emailLink($label, $subject)
    {
        return $this->mailTo(CONTACT_EMAIL, $label, [
            'subject' => $subject,
            'encode'  => 'javascript'
        ]);
    }

    /**
     * Return a <link rel="canonical"> tag for the current page.
     * Since the URL is user-controlled, it needs to be escaped
     * for output. If the URL is suspicious, we render nothing.
     */
    public function linkToCanonicalUrl()
    {
        // Strip query strings and fragments
        $path = parse_url($this->currentUrl, PHP_URL_PATH);
        if ($path === false || $path === null) {
            return '';
        }

        // Reject path traversal attempts
        if (strpos($path, '..') !== false) {
            return '';
        }

        // Reject anything with characters outside normal URL paths
        if (!preg_match('#^/[a-zA-Z0-9_./-]*$#', $path)) {
            return '';
        }

        $url = 'http://6502.org' . $path;
        return $this->tag('link', ['rel' => 'canonical', 'href' => $url]);
    }

    /**
     * Link to a file in the Documents Archive.
     * Throws an exception if the file does not exist in the database.
     *
     *   <?= $this->linkToDocumentFile('microcomputers/synertek-sym1/manuals/sym1_reference_manual.pdf', 'SYM-1 Reference Manual') ?>
     *   <?= $this->linkToDocumentFile('downloads/mini-projects/datapod/datapod_source_code.zip', 'Download') ?>
     */
    public function linkToDocumentFile($path, $label)
    {
        if (DocumentFile::findByPath($path) === null) {
            throw new Exception("linkToDocumentFile: \"$path\" not found");
        }
        return $this->linkTo($label, '/documents/' . $path);
    }

}
