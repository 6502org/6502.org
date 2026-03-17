<?php

class DocumentsHelper extends ApplicationHelper
{
    public function breadcrumbs()
    {
        $crumbs = [];
        $last = count($this->folders) - 1;

        foreach ($this->folders as $i => $folder) {
            if ($i == $last) {
                $crumbs[] = $this->h($folder->title);
            } else {
                $crumbs[] = $this->linkTo($folder->title, $folder->path());
            }
        }

        return $this->contentTag('div', implode(' / ', $crumbs),
                                 ['class' => 'breadcrumbs']);
    }

    /**
     * Count consecutive obsolete (and visible) files immediately
     * preceding $doc in the file list. This matches what the JS
     * reveal will do when walking previousElementSibling.
     */
    public function countPrecedingObsolete($doc, $files)
    {
        $count = 0;
        foreach ($files as $file) {
            if ($file->id == $doc->id) { break; }
            if ($file->obsolete && $file->visible) {
                $count++;
            } elseif ($file->visible) {
                $count = 0;
            }
        }
        return $count;
    }

    public function fileFormatIcon($doc)
    {
        $ext = pathinfo($doc->filename, PATHINFO_EXTENSION);
        $ext = strtolower($ext);
        return "files/$ext.gif";
    }

    public function numberToHumanSizeWithDotZero($num)
    {
        $humanSize = $this->numberToHumanSize($num);
        if (strpos($humanSize, '.') === false) {
            list($numericPart, $unitsPart) = explode(' ', $humanSize);
            $humanSize = $numericPart . '.0 ' . $unitsPart;
        }
        return $humanSize;
    }

}
