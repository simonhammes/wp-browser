<?php

namespace tad\WPBrowser\Tests\Support;

function rrmdir($src) {
	if (!file_exists($src)) {
		return;
	}

	$dir = opendir($src);
	while (false !== ($file = readdir($dir))) {
		if (($file != '.') && ($file != '..')) {
			$full = $src . '/' . $file;
			if (is_dir($full)) {
				rrmdir($full);
			} else {
				unlink($full);
			}
		}
	}
	closedir($dir);
	rmdir($src);
}

function importDump($dumpFile, $dbName, $dbUser = 'root', $dbPass = 'root', $dbHost = 'localhost', &$output = null) {
	$commandTemplate = 'mysql --host=%s --user=%s %s %s < %s';
	$dbPassEntry = $dbPass ? '--password=' . $dbPass : '';
	$command = sprintf($commandTemplate, $dbHost, $dbUser, $dbPassEntry, $dbName, $dumpFile);
	exec($command, $output, $status);

	return $status;
}