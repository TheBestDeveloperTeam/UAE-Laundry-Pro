<?php

declare(strict_types=1);

require_once __DIR__ . '/CredentialLoader.php';

$repoRoot = dirname(__DIR__, 2);
$creds = LaundryPro\Deploy\CredentialLoader::load($repoRoot);
$paths = $creds['deploy_paths'];
$origin = $paths->siteOriginFromApplyUrl($creds['deploy_apply_url'] ?? '');
$probePaths = $paths->httpProbePaths();
$httpProbes = [];
foreach ($probePaths as $key => $rel) {
    $httpProbes[$key] = $origin . $rel;
}

$out = [
    'ssh' => $creds['ssh'],
    'ftp' => $creds['ftp'],
    'deploy' => $creds['deploy'] ?? [],
    'health_url' => $creds['health_url'],
    'deploy_paths' => $paths->toArray(),
    'http_probes' => $httpProbes,
];

echo json_encode($out, JSON_THROW_ON_ERROR);
