<?php

class ApplicationHelper extends Mad_View_Helper_Base
{
    public function milestoneYears()
    {
        $foundedYear = 1999;
        $foundedMonth = 6;
        $now = getdate();
        $years = $now['year'] - $foundedYear;
        if ($now['mon'] < $foundedMonth) {
            $years--;
        }
        return floor($years / 5) * 5;
    }
}
