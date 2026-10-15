<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Env;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;

final class DeployAutomationController
{
    public function apply(Request $request): void
    {
        if (!$this->authorize($request)) {
            Response::json(['success' => false, 'code' => 'UNAUTHORIZED', 'message' => 'Invalid deploy token'], 401);
            return;
        }

        if (!$this->httpDeployEnabled()) {
            Response::json(['success' => false, 'code' => 'DISABLED', 'message' => 'HTTP deploy disabled'], 403);
            return;
        }

        $body = $request->body();
        $package = trim((string) ($body['package'] ?? 'deploy_staging/cloud-cpanel-upload.zip'));
        $deployRoot = $this->deployRoot();

        require_once dirname(__DIR__, 2) . '/scripts/automation/ReleaseAutomation.php';

        $engine = new \ReleaseAutomation(dirname(__DIR__, 2) . '/scripts/automation');
        $result = $engine->applyPackage($deployRoot, $package);

        $cloudApiDir = dirname(__DIR__, 2);
        \ReleaseAutomation::writeStatusFile($cloudApiDir, [
            'action' => 'apply',
            'package' => $package,
            'exit_code' => $result['exitCode'],
            'output_tail' => mb_substr($result['output'], -8000),
        ]);

        $ok = $result['exitCode'] === 0;
        Response::json([
            'success' => $ok,
            'code' => $ok ? 'DEPLOY_APPLY_OK' : 'DEPLOY_APPLY_FAILED',
            'data' => [
                'exit_code' => $result['exitCode'],
                'output' => mb_substr($result['output'], 0, 120000),
            ],
        ], $ok ? 200 : 500);
    }

    public function logs(Request $request): void
    {
        if (!$this->authorize($request)) {
            Response::json(['success' => false, 'code' => 'UNAUTHORIZED', 'message' => 'Invalid deploy token'], 401);
            return;
        }

        $lines = max(10, min(500, (int) $request->query('lines', 80)));
        require_once dirname(__DIR__, 2) . '/scripts/automation/ReleaseAutomation.php';
        $result = \ReleaseAutomation::tailLogs($this->deployRoot(), $lines);

        Response::json([
            'success' => true,
            'code' => 'DEPLOY_LOGS',
            'data' => ['output' => $result['output']],
        ]);
    }

    public function status(Request $request): void
    {
        if (!$this->authorize($request)) {
            Response::json(['success' => false, 'code' => 'UNAUTHORIZED', 'message' => 'Invalid deploy token'], 401);
            return;
        }

        $path = dirname(__DIR__, 2) . '/storage/deploy_last.json';
        if (!is_file($path)) {
            Response::json(['success' => true, 'code' => 'DEPLOY_STATUS', 'data' => null]);
            return;
        }

        $raw = file_get_contents($path);
        $decoded = is_string($raw) ? json_decode($raw, true) : null;
        Response::json([
            'success' => true,
            'code' => 'DEPLOY_STATUS',
            'data' => is_array($decoded) ? $decoded : null,
        ]);
    }

    private function deployRoot(): string
    {
        return dirname(__DIR__, 3);
    }

    private function authorize(Request $request): bool
    {
        $expected = (string) Env::get('DEPLOY_AUTOMATION_TOKEN', '');
        if ($expected === '') {
            return false;
        }

        $token = $request->header('X-LaundryPro-Deploy-Token', '') ?? '';
        if ($token === '') {
            $auth = $request->header('Authorization', '') ?? '';
            if (str_starts_with($auth, 'Bearer ')) {
                $token = trim(substr($auth, 7));
            }
        }

        return $token !== '' && hash_equals($expected, $token);
    }

    private function httpDeployEnabled(): bool
    {
        $flag = Env::get('DEPLOY_HTTP_ENABLED', 'true');
        return filter_var($flag, FILTER_VALIDATE_BOOLEAN);
    }
}
