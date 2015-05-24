<?php

class DocumentsHelper extends ApplicationHelper
{
    public function breadcrumbs()
    {
        $crumbs = array();
        $last = count($this->sections) -1;

        foreach ($this->sections as $i => $section) {
            if ($i == $last) {
                $crumbs[] = $section['title_sidebar'];
            } else {
                $crumbs[] = $this->linkTo($section['title_sidebar'], $section['url']);
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

}