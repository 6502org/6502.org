<?php

class ApplicationHelper extends Mad_View_Helper_Base
{
    public function isProduction()
    {
        return MAD_ENV == 'production';
    }

    public function emailLink($label, $subject)
    {
        return $this->mailTo(CONTACT_EMAIL, $label, [
            'subject' => $subject,
            'encode'  => 'javascript'
        ]);
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
