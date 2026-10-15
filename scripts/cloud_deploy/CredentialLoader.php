<?php

declare(strict_types=1);

namespace LaundryPro\Deploy;

require_once __DIR__ . '/DeployPaths.php';

final class CredentialLoader
{
    /**
     * SSH deploy credentials (flat, backward compatible) plus optional `ftp` block.
     *
     * @return array{
     *   host:string,port:int,username:string,password:?string,identity_file:?string,
     *   remote_home:string,remote_deploy_root:string,health_url:string,
     *   deploy_paths: DeployPaths,
     *   ssh: array{host:string,port:int,username:string,password:?string,identity_file:?string,remote_home:string},
     *   ftp: array{host:string,port:int,username:string,password:?string,remote_path:string}
     * }
     */
    public static function load(string $repoRoot): array
    {
        $bundle = self::loadBundle($repoRoot);
        $ssh = $bundle['ssh'];
        $paths = $bundle['deploy_paths'];

        $deploy = $bundle['deploy'];

        return array_merge($ssh, [
            'remote_deploy_root' => $paths->deployRoot(),
            'health_url' => self::healthUrlForHost($ssh['host']),
            'deploy_automation_token' => $deploy['automation_token'],
            'deploy_apply_url' => $deploy['apply_url'],
            'deploy_logs_url' => $deploy['logs_url'],
            'deploy_status_url' => $deploy['status_url'],
            'deploy_paths' => $paths,
            'ssh' => $ssh,
            'ftp' => $bundle['ftp'],
            'deploy' => $deploy,
        ]);
    }

    /**
     * @return array{
     *   ssh: array{host:string,port:int,username:string,password:?string,identity_file:?string,remote_home:string},
     *   ftp: array{host:string,port:int,username:string,password:?string,remote_path:string},
     *   deploy: array{automation_token:string,apply_url:string,logs_url:string,status_url:string},
     *   deploy_paths: DeployPaths
     * }
     */
    public static function loadBundle(string $repoRoot): array
    {
        $iniPath = $repoRoot . '/scripts/cloud_deploy/credentials.ini';
        $legacyPath = $repoRoot . '/.ssh-credentials-details';

        $ssh = [
            'host' => '',
            'port' => 22,
            'username' => '',
            'password' => null,
            'identity_file' => null,
            'remote_home' => '',
        ];

        $ftp = [
            'host' => '',
            'port' => 21,
            'username' => '',
            'password' => null,
            'remote_path' => '',
        ];

        $deploy = [
            'automation_token' => '',
            'apply_url' => '',
            'logs_url' => '',
            'status_url' => '',
        ];

        $lockFtpPort = false;
        $iniRaw = [];

        if (is_file($iniPath)) {
            $parsed = parse_ini_file($iniPath, false, INI_SCANNER_TYPED);
            if (is_array($parsed)) {
                $iniRaw = $parsed;
                $ssh['host'] = trim((string) ($parsed['host'] ?? ''));
                $ssh['port'] = (int) ($parsed['port'] ?? 22);
                $ssh['username'] = trim((string) ($parsed['username'] ?? ''));
                $ssh['password'] = isset($parsed['password']) ? (string) $parsed['password'] : null;
                $ssh['identity_file'] = isset($parsed['identity_file']) ? trim((string) $parsed['identity_file']) : null;
                $ssh['remote_home'] = self::normalizeRemoteHome((string) ($parsed['remote_home'] ?? ''));
                $ftp['host'] = trim((string) ($parsed['ftp_host'] ?? ''));
                $ftp['port'] = (int) ($parsed['ftp_port'] ?? 21);
                $ftp['username'] = trim((string) ($parsed['ftp_username'] ?? ''));
                $ftp['password'] = isset($parsed['ftp_password']) ? (string) $parsed['ftp_password'] : null;
                $ftp['remote_path'] = self::normalizeRemoteHome((string) ($parsed['ftp_remote_path'] ?? ''));
                $lockFtpPort = array_key_exists('ftp_port', $parsed);
                $deploy['automation_token'] = trim((string) ($parsed['deploy_automation_token'] ?? ''));
                $deploy['apply_url'] = trim((string) ($parsed['deploy_apply_url'] ?? ''));
                $deploy['logs_url'] = trim((string) ($parsed['deploy_logs_url'] ?? ''));
                $deploy['status_url'] = trim((string) ($parsed['deploy_status_url'] ?? ''));
            }
        }

        if (is_file($legacyPath)) {
            self::parseLegacyCredentials($legacyPath, $ssh, $ftp, $lockFtpPort);
        }

        if ($ssh['host'] === '') {
            $ssh['host'] = 'laundrypro-cloudapi.magnificentsolution.co.in';
        }

        if ($ssh['remote_home'] === '' && $ftp['remote_path'] !== '') {
            $ssh['remote_home'] = $ftp['remote_path'];
        }

        if ($ssh['username'] === '' || $ssh['remote_home'] === '') {
            throw new \RuntimeException(
                'Missing SSH deploy config. Copy scripts/cloud_deploy/credentials.example.ini to credentials.ini '
                . 'or set username + deploy path in .ssh-credentials-details.'
            );
        }

        $baseUrl = 'https://laundrypro-cloudapi.magnificentsolution.co.in';
        if ($deploy['apply_url'] === '') {
            $deploy['apply_url'] = $baseUrl . '/api/v1/internal/deploy/apply';
        }
        if ($deploy['logs_url'] === '') {
            $deploy['logs_url'] = $baseUrl . '/api/v1/internal/deploy/logs';
        }
        if ($deploy['status_url'] === '') {
            $deploy['status_url'] = $baseUrl . '/api/v1/internal/deploy/status';
        }

        $paths = DeployPaths::forBundle($ssh, $ftp, $iniRaw);
        if ($ftp['remote_path'] === '' && $paths->deployRoot() !== '') {
            $ftp['remote_path'] = $paths->deployRoot();
        }
        if ($ssh['remote_home'] === '' && $paths->deployRoot() !== '') {
            $ssh['remote_home'] = $paths->deployRoot();
        }

        return ['ssh' => $ssh, 'ftp' => $ftp, 'deploy' => $deploy, 'deploy_paths' => $paths];
    }

    public static function normalizeRemoteHome(string $path): string
    {
        return rtrim(trim($path), '/\\');
    }

    public static function toRemotePath(string $remoteHome, string $suffix): string
    {
        $suffix = ltrim(str_replace('\\', '/', $suffix), '/');
        $base = self::normalizeRemoteHome($remoteHome);

        return $suffix === '' ? $base : $base . '/' . $suffix;
    }

    public static function scpTarget(string $sshTarget, string $remoteHome, string $suffix): string
    {
        $path = self::toRemotePath($remoteHome, $suffix);

        return $sshTarget . ':' . $path;
    }

    private static function healthUrlForHost(string $host): string
    {
        if (filter_var($host, FILTER_VALIDATE_IP)) {
            return 'https://laundrypro-cloudapi.magnificentsolution.co.in/api/v1/health';
        }

        return 'https://' . $host . '/api/v1/health';
    }

    /**
     * @param array{host:string,port:int,username:string,password:?string,identity_file:?string,remote_home:string} $ssh
     * @param array{host:string,port:int,username:string,password:?string,remote_path:string} $ftp
     */
    private static function parseLegacyCredentials(string $path, array &$ssh, array &$ftp, bool $lockFtpPort = false): void
    {
        $lines = file($path, FILE_IGNORE_NEW_LINES);
        if ($lines === false) {
            return;
        }

        $section = 'ssh';
        $count = count($lines);
        for ($i = 0; $i < $count; $i++) {
            $line = trim($lines[$i]);
            if ($line === '') {
                continue;
            }
            if ($line === 'FTP') {
                $section = 'ftp';
                continue;
            }

            if ($section === 'ftp') {
                self::parseFtpLine($line, $ftp, $lockFtpPort);
                continue;
            }

            if (str_starts_with($line, 'username:')) {
                if ($ssh['username'] === '') {
                    $ssh['username'] = trim(substr($line, strlen('username:')));
                }
            } elseif (str_starts_with($line, 'password:')) {
                if ($ssh['password'] === null || $ssh['password'] === '') {
                    $ssh['password'] = trim(substr($line, strlen('password:')));
                }
            } elseif ($line === 'Shared IP Address' && $i + 1 < $count) {
                $ip = trim($lines[$i + 1]);
                if ($ssh['host'] === '' && filter_var($ip, FILTER_VALIDATE_IP)) {
                    $ssh['host'] = 'laundrypro-cloudapi.magnificentsolution.co.in';
                }
            } elseif (preg_match('#^/home/[^/]+/public_html/#', $line)) {
                if ($ssh['remote_home'] === '') {
                    $ssh['remote_home'] = self::normalizeRemoteHome($line);
                }
            } elseif (self::isLocalPrivateKeyPath($line)) {
                if (($ssh['identity_file'] === null || $ssh['identity_file'] === '') && is_file($line)) {
                    $ssh['identity_file'] = $line;
                }
            } elseif (!str_contains($line, ':') && !str_starts_with($line, 'ssh-rsa') && !str_starts_with($line, 'Generating')) {
                if ($ssh['remote_home'] === '' && preg_match('#public_html/#', $line)) {
                    $ssh['remote_home'] = self::normalizeRemoteHome($line);
                }
            }
        }
    }

    /** @param array{host:string,port:int,username:string,password:?string,remote_path:string} $ftp */
    private static function parseFtpLine(string $line, array &$ftp, bool $lockFtpPort = false): void
    {
        if (preg_match('#^port:\s*(\d+)#i', $line, $m)) {
            if (!$lockFtpPort) {
                $ftp['port'] = (int) $m[1];
            }
        } elseif (preg_match('#^username:\s*(.+)$#i', $line, $m)) {
            $ftp['username'] = trim($m[1]);
        } elseif (preg_match('#^password:\s*(.+)$#i', $line, $m)) {
            $ftp['password'] = trim($m[1]);
        } elseif (preg_match('#^host:\s*(.+)$#i', $line, $m)) {
            $ftp['host'] = trim($m[1]);
        } elseif (preg_match('#^path:\s*(.+)$#i', $line, $m)) {
            $ftp['remote_path'] = self::normalizeRemoteHome(trim($m[1]));
        }
    }

    private static function isLocalPrivateKeyPath(string $line): bool
    {
        $line = trim($line);
        if ($line === '' || str_ends_with($line, '.pub') || str_ends_with($line, '.ppk')) {
            return false;
        }

        return preg_match('#^[A-Za-z]:[\\\\/].*cloud-laudry-pro-ssh$#', $line) === 1;
    }
}
