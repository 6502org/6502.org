<?php

class ContentsHelper extends ApplicationHelper
{
    public function getRandomForumContributors()
    {
        $all = $this->_getTop100();

        $keys = array_keys($all);
        shuffle($keys);

        $selected = [];
        foreach ($keys as $key) { $selected[$key] = $all[$key]; }
        return $selected;
    }

	protected function _getTop100()
	{
		// Top 100 forum contributors by posts as of 24-Mar-2026, excluding people in
		// the "Maintainers" and "In Memoriam" sections on the "About" page.  Don't start
		// posting a lot to make it onto this list; we'll probably never update it.  Also,
		// don't change your forum avatar if you're going to ask us to update it here too. ;)
        return [
            'BigDumbDinosaur'  => 'bigdumbdinosaur.png',  // 1045_1334204384
            'Dr Jefyll'        => 'dr_jefyll.png',        // 1096_1698810075
            'Arlet'            => 'arlet.png',            // 1217_1364037650
            'barrym95838'      => 'barrym95838.png',      // 1643_1379315394
            '8BIT'             => '8bit.png',             // 7_1334155446
            'drogon'           => 'drogon.png',           // 2699_1690488694
            'ttlworks'         => 'ttlworks.png',         // 1552_1696421707
            'floobydust'       => 'floobydust.png',       // 1600_1511836529
            'cbmeeks'          => 'cbmeeks.png',          // 535_1435588483
            'BillO'            => 'billo.png',            // 997_1522250335
            'enso'             => 'enso.png',             // 1540_1370403099
            'Dajgoro'          => 'dajgoro.png',          // 1289_1352902813
            'MichaelM'         => 'michaelm.png',         // 1485_1436234350
            'cjs'              => 'cjs.png',              // 2898_1575373894
            'Proxy'            => 'proxy.png',            // 2832_1578972501
            'banedon'          => 'banedon.png',          // 1672_1440024349
            'Oneironaut'       => 'oneironaut.png',       // 2130_1740293156
            'GaBuZoMeu'        => 'gabuzomeu.png',        // 2444_1488403845
            'Michael'          => 'michael.png',          // 1587_1579941278
            'cbscpe'           => 'cbscpe.png',           // 1692_1427641272
            'Rob Finch'        => 'rob_finch.png',        // 61_1379578250
            'Drass'            => 'drass.png',            // 2197_1446931153
            'Yuri'             => 'yuri.png',             // 4073_1677628787
            'AndrewP'          => 'andrewp.png',          // 3700_1638892637
            'Druzyek'          => 'druzyek.png',          // 1978_1506491285
            'Alarm Siren'      => 'alarm_siren.png',      // 2386_1753746538
            'dclxvi'           => 'dclxvi.png',           // 221_1334437024
            'Sheep64'          => 'sheep64.png',          // 3330_1679579710
            'commodorejohn'    => 'commodorejohn.png',    // 2254_1757052928
            'akohlbecker'      => 'akohlbecker.png',      // 3656_1758403786
            'Ruud'             => 'ruud.png',             // 187_1550423138
            'KC9UDX'           => 'kc9udx.png',           // 1895_1472271197
            'jac_goudsmit'     => 'jac_goudsmit.png',     // 1282_1387315751
            'Windfall'         => 'windfall.png',         // 1328_1605465875
            'HansO'            => 'hanso.png',            // 169_1645710525
            'org'              => 'org.png',              // 1508_1362548654
            'wayfarer'         => 'wayfarer.png',         // 4095_1746459905
            'AndersNielsen'    => 'andersnielsen.png',    // 3783_1649003855
            'and3rson'         => 'and3rson.png',         // 4063_1685475649
            'RichCini'         => 'richcini.png',         // 136_1607126664
            '1024MAK'          => '1024mak.png',          // 2126_1432160631
            'speculatrix'      => 'speculatrix.png',      // 2759_1523373116
            'PaulF'            => 'paulf.png',            // 990_1334161615
            'Agumander'        => 'agumander.png',        // 2828_1576482880
            'hjalfi'           => 'hjalfi.png',           // 2587_1507902239
            'JuanGg'           => 'juangg.png',           // 3120_1581265642
            'CountChocula'     => 'countchocula.png',     // 3748_1636420421
            'jfoucher'         => 'jfoucher.png',         // 3470_1609111184
            'allisonlastname'  => 'allisonlastname.png',  // 4081_1679922492
            'ptorric'          => 'ptorric.png',          // 429_1544262920
            'gilhad'           => 'gilhad.png',           // 4344_1706248349
            'mvk'              => 'mvk.png',              // 2459_1561635200
            'Hobbit1972'       => 'hobbit1972.png',       // 2080_1433494351
            '65f02'            => '65f02.png',            // 3306_1594557092
            'Individual_Solid' => 'individual_solid.png', // 3619_1630041282
            'visrealm'         => 'visrealm.png',         // 3681_1693465254
            'James_Parsons'    => 'james_parsons.png',    // 1646_1376690014
            'richardc64'       => 'richardc64.png',       // 1633_1646150252
            'Johnny Starr'     => 'johnny_starr.png',     // 1497_1375888789
            'BB8'              => 'bb8.png',              // 3405_1604229432
            'willie68'         => 'willie68.png',         // 3939_1664870173
            'Alamorobotics'    => 'alamorobotics.png',    // 2203_1449070346
            'VinCBR900'        => 'vincbr900.png',        // 2568_1680104676
            'drfiemost'        => 'drfiemost.png',        // 2333_1465318419
            'Shawn Odekirk'    => 'shawn_odekirk.png',    // 3236_1585110337
            'fredericsegard'   => 'fredericsegard.png',   // 3328_1596660835
            'satpro'           => 'satpro.png',           // 2047_1418628416
            'jim30109'         => 'jim30109.png',         // 2471_1491144604
            'Firefox6502'      => 'firefox6502.png',      // 3503_1612235012
            'lenzjo'           => 'lenzjo.png',           // 2120_1434013542
            'tius'             => 'tius.png',             // 3746_1699171074
            'Floopy'           => 'floopy.png',           // 2830_1532578237
            'joanlluch'        => 'joanlluch.png',        // 2994_1565509265
            'fschuhi'          => 'fschuhi.png',          // 2945_1554142039
            'glitch'           => 'glitch.png',           // 3371_1601924412
            'Mr SQL'           => 'mr_sql.png',           // 2158_1439573409
            'pnoyes'           => 'pnoyes.png',           // 2280_1460655618
            'mkarcz'           => 'mkarcz.png',           // 1342_1334626769
            'nkeck72'          => 'nkeck72.png',          // 2161_1440352067
            'LGB'              => 'lgb.png',              // 367_1357851831
            'Broti'            => 'broti.png',            // 4214_1694109078
            'emeb'             => 'emeb.png',             // 2964_1552063068
            'CommodoreZ'       => 'commodorez.png',       // 2777_1523274187
            'davidmjc'         => 'davidmjc.png',         // 3169_1579479794
            'Konrad_B'         => 'konrad_b.png',         // 927_1689689862
            'SpiradiscGuy'     => 'spiradiscguy.png',     // 4149_1685576243
            'DavidBuchanan'    => 'davidbuchanan.png',    // 2122_1483483305
            'jdimeglio'        => 'jdimeglio.png',        // 3428_1606795943
            'ytropek'          => 'ytropek.png',          // 4304_1706798134
            'N2TheRed'         => 'n2thered.png',         // 2311_1474513480
            'rob42'            => 'rob42.png',            // 4395_1712185742
            'chessdoger'       => 'chessdoger.png',       // 2099_1426631739
            'player55328'      => 'player55328.png',      // 1657_1376090871
            'pjeaton'          => 'pjeaton.png',           // 434_1609966553
            'rupy'             => 'rupy.png',             // 2833_1536685024
            'railsrust'        => 'railsrust.png',        // 2954_1552944804
            'zuiko21'          => 'zuiko21.png',          // 1199_1724858217
            'aleferri'         => 'aleferri.png',         // 3568_1619951557
            'Osi'              => 'osi.png',              // 3880_1652519518
            'Collen'           => 'collen.png',           // 2892_1575454170
        ];
    }
}