<?php

class DocumentsController extends ApplicationController
{
    public function index()
    {
        $path = $this->params['path'];
        $slugs = array_filter(explode('/', trim($path, '/')));
        $expectedCount = count($slugs) + 1; // +1 for root "documents"

        $this->folders = DocumentFolder::resolvePath($path);

        // All slugs resolved to folders — display the last one.
        if (count($this->folders) == $expectedCount) {
            $this->folder = end($this->folders);
            if (!$this->folder->visible && $this->_isProduction()) {
                $this->redirectTo(['controller' => 'documents', 'action' => 'index']);
            }
            return;
        }

        // The last slug didn't match a folder. Check if it's a filename.
        if (count($this->folders) > 0) {
            $currentFolder = end($this->folders);
            $lastSlug = end($slugs);
            $doc = $currentFolder->findFile($lastSlug);

            if ($doc) {
                if ($doc->isReadable()) {
                    $this->_renderErrorForServerMisconfiguration($doc);
                } elseif (!empty($doc->mirror_url)) {
                    $this->redirectTo($doc->mirror_url);
                } else {
                    $this->flash['alert'] = "\"{$doc->title}\" is not currently available.";
                    $this->redirectTo($currentFolder->path());
                }
                return;
            }
        }

        // Unknown path. Redirect to the last known-good folder.
        $this->redirectTo($this->_lastFolderUrl());
    }

    protected function _lastFolderUrl()
    {
        if (count($this->folders) > 0) {
            return end($this->folders)->path();
        }
        return '/';
    }

    // The webserver should serve document files directly, never through
    // PHP. If a readable file reaches this controller, the server is
    // misconfigured (e.g. missing rewrite rules).
    protected function _renderErrorForServerMisconfiguration($doc)
    {
        $template = file_get_contents(MAD_ROOT . '/public/500.html');
        $replacement = $this->_view->render(
            'Documents/_file_error.html', 
            ['url' => $this->_request->getUri()]);

        $html = preg_replace(
            '/<p class="message">.*?<\/p>/s',
            $replacement,
            $template
        );

        $this->render(['text' => $html, 'status' => 500]);
    }

}
