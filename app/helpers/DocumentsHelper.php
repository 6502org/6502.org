<?php

class DocumentsHelper extends ApplicationHelper
{
    public function breadcrumbs()
    {
        $crumbs = array();
        $last = count($this->folders) -1;

        foreach ($this->folders as $i => $folder) {
            if ($i == $last) {
                $crumbs[] = $this->h($folder['title']);
            } else {
                $crumbs[] = $this->linkTo($folder['title'], $folder['url']);
            }
        }

        return $this->contentTag('div', implode(' &gt; ', $crumbs),
                                 array('style' => 'padding-bottom: 10px;'));
    }

    public function fileFormatIcon($docItem)
    {
        $ext = pathinfo($docItem['filename'], PATHINFO_EXTENSION);
        $ext = strtolower($ext);
        return "files/$ext.gif";
    }

    public function numberToHumanSizeWithDotZero($num)
    {
        $humanSize = $this->numberToHumanSize($zero);
        if (strpos($humanSize, '.') === false) {
            list($numericPart, $unitsPart) = explode(' ', $humanSize);
            $humanSize = $numericPart . '.0 ' . $unitsPart;
        }
        return $humanSize;
    }

}