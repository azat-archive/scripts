#!/usr/bin/env php
<?php

function findGitDir($start)
{
    $dir = $start;

    while (true) {
        $dir = realpath($dir);

        if (preg_match('@/.git$@', $dir)) {
            return $dir;
        }
        if (is_dir($dir . '/.git/')) {
            return realpath($dir . '/.git/');
        }

        $dir .= '/../';
    }
}

/* TODO: getopts */
$dir = findGitdir(getcwd());
$format = '%s (%h)';
$range = ($argc > 1) ? $argv[1] : '';

$output = array();
exec(sprintf('env GIT_DIR=%s git log --format="%s" %s', escapeshellarg($dir), $format, $range), $output);

$history = array();
foreach ($output as $line) {
    preg_match('@^(\[(?P<group1>.*)\]|(?P<group2>.*):)(?P<subject>.*) \((?P<sha>[0-9a-f]*)\)@', $line, $m);
    $m['group'] = $m['group2'] ?: $m['group1'];

    if (empty($history[$m['group']])) {
        $history[$m['group']] = array();
    }
    $history[$m['group']][] = sprintf('%s (%s)', $m['subject'], $m['sha']);
}

foreach ($history as $group => $changes) {
    printf("%s: \n", $group);

    foreach ($changes as $change) {
        printf("- %s\n", trim($change));
    }
}

