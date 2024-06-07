<?php

    include_once('fix_mysql.inc.php');
    $lnk = mysql_connect("localhost", "pentesterlab", "pentesterlab");
    $db = mysql_select_db('photoblog', $lnk);

?>
