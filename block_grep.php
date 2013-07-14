#!/usr/bin/env php
<?

/**
 * From https://gist.github.com/azat/5565095
 */

if ($argc < 3) {
    fprintf(STDERR, "Usage: %s [-v | --invert-match] pattern file-name\n",
            $argv[0]);
    exit(1);
}

$options = array();
$options = array_merge($options, getopt(
    'v',
    array(
        'invert-match',
    )
));
// TODO: add helper.
if (array_key_exists('v', $options)) {
    // TODO: false is because PHP parse options in that way.
    $options['invert-match'] = false;
}
$options['pattern'] = array_pop($argv);
$options['file'] = array_pop($argv);

preg_match_all('@(.*)[\n]{2,}@Uis', file_get_contents($options['file']),
               $matches, PREG_SET_ORDER);
$matchedBlocks = 0;
foreach ($matches as $match) {
    $content = $match[0];

    $matched = preg_match($options['pattern'], $content);
    // TODO: add helper.
    if (array_key_exists('invert-match', $options)) {
        $matched = !$matched;
    }

    if ($matched) {
        $matchedBlocks++;
        echo $content;
    }
}

fprintf(STDERR, "Examined %d blocks. Matched %d blocks.\n", count($matches), $matchedBlocks);
