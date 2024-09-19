<?php

define('DIR_SRC', __DIR__);
define('DIR_ROOT', DIR_SRC . DIRECTORY_SEPARATOR . '..');
define('DIR_CACHE', DIR_ROOT . DIRECTORY_SEPARATOR . 'cache');
define('DIR_VENDOR', DIR_ROOT . DIRECTORY_SEPARATOR . 'vendor');
define('FILE_TESTING_LOOP', sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'liveness-probe');