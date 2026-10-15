<?php

declare(strict_types=1);

namespace LaundryPro\Deploy;

/**
 * Maps FTP deploy tree (DEPLOY_ROOT) to HTTP document root (Option A vs B).
 */
final class DeployPaths
{
    public const LAYOUT_OPTION_A = 'option_a';

    public const LAYOUT_OPTION_B = 'option_b';

    private string $deployRoot;

    private string $httpDocroot;

    private string $layout;

    private function __construct(string $deployRoot, string $httpDocroot, string $layout)
    {
        $this->deployRoot = CredentialLoader::normalizeRemoteHome($deployRoot);
        $this->httpDocroot = CredentialLoader::normalizeRemoteHome($httpDocroot);
        $this->layout = self::normalizeLayout($layout);
    }

    /**
     * @param array<string, scalar|null> $ini
     */
    public static function fromIni(array $ini, string $deployRootFallback): self
    {
        $deployRoot = CredentialLoader::normalizeRemoteHome(
            trim((string) ($ini['deploy_root'] ?? $ini['remote_home'] ?? $deployRootFallback))
        );
        if ($deployRoot === '') {
            $deployRoot = CredentialLoader::normalizeRemoteHome(
                trim((string) ($ini['ftp_remote_path'] ?? ''))
            );
        }

        $defaultDocroot = CredentialLoader::toRemotePath($deployRoot, 'cloud-api/public');
        $httpDocroot = trim((string) ($ini['http_docroot'] ?? ''));
        if ($httpDocroot === '') {
            $httpDocroot = $defaultDocroot;
        } else {
            $httpDocroot = CredentialLoader::normalizeRemoteHome($httpDocroot);
        }

        $layout = trim((string) ($ini['deploy_layout'] ?? ''));
        if ($layout === '') {
            $layout = self::inferLayout($deployRoot, $httpDocroot);
        }

        return new self($deployRoot, $httpDocroot, $layout);
    }

    public static function forBundle(array $ssh, array $ftp, array $ini = []): self
    {
        $fallback = $ssh['remote_home'] !== '' ? $ssh['remote_home'] : $ftp['remote_path'];

        return self::fromIni($ini, $fallback);
    }

    public function deployRoot(): string
    {
        return $this->deployRoot;
    }

    public function httpDocroot(): string
    {
        return $this->httpDocroot;
    }

    public function layout(): string
    {
        return $this->layout;
    }

    public function isOptionA(): bool
    {
        return $this->layout === self::LAYOUT_OPTION_A;
    }

    public function isOptionB(): bool
    {
        return $this->layout === self::LAYOUT_OPTION_B;
    }

    public function remoteCloudApiRoot(): string
    {
        return CredentialLoader::toRemotePath($this->deployRoot, 'cloud-api');
    }

    public function remotePublicRoot(): string
    {
        return CredentialLoader::toRemotePath($this->deployRoot, 'cloud-api/public');
    }

    public function remoteStagingZip(): string
    {
        return CredentialLoader::toRemotePath($this->deployRoot, 'deploy_staging/cloud-cpanel-upload.zip');
    }

    /**
     * @return array{
     *   deploy_root:string,http_docroot:string,deploy_layout:string,
     *   cloud_api_root:string,public_web_root:string,expected_docroot_option_a:string
     * }
     */
    public function toArray(): array
    {
        return [
            'deploy_root' => $this->deployRoot,
            'http_docroot' => $this->httpDocroot,
            'deploy_layout' => $this->layout,
            'cloud_api_root' => $this->remoteCloudApiRoot(),
            'public_web_root' => $this->remotePublicRoot(),
            'expected_docroot_option_a' => $this->remotePublicRoot(),
        ];
    }

    /**
     * @return list<string>
     */
    public function alignmentWarnings(string $ftpRemotePath, string $sshRemoteHome): array
    {
        $warnings = [];
        if ($ftpRemotePath !== '' && $ftpRemotePath !== $this->deployRoot) {
            $warnings[] = "ftp_remote_path ({$ftpRemotePath}) != deploy_root ({$this->deployRoot})";
        }
        if ($sshRemoteHome !== '' && $sshRemoteHome !== $this->deployRoot) {
            $warnings[] = "remote_home ({$sshRemoteHome}) != deploy_root ({$this->deployRoot})";
        }
        if ($this->isOptionA() && $this->httpDocroot !== $this->remotePublicRoot()) {
            $warnings[] = 'Option A: http_docroot should be {deploy_root}/cloud-api/public (got ' . $this->httpDocroot . ')';
        }
        if ($this->isOptionB() && $this->httpDocroot !== $this->deployRoot) {
            $warnings[] = 'Option B: http_docroot should equal deploy_root (got ' . $this->httpDocroot . ')';
        }

        return $warnings;
    }

    public function siteOriginFromApplyUrl(string $applyUrl): string
    {
        $parts = parse_url($applyUrl);
        if (!is_array($parts) || !isset($parts['scheme'], $parts['host'])) {
            return 'https://laundrypro-cloudapi.magnificentsolution.co.in';
        }

        $origin = $parts['scheme'] . '://' . $parts['host'];
        if (isset($parts['port'])) {
            $origin .= ':' . $parts['port'];
        }

        return $origin;
    }

    public function bootstrapApplyUrl(string $applyUrl): string
    {
        $origin = $this->siteOriginFromApplyUrl($applyUrl);
        if ($this->isOptionA()) {
            return $origin . '/lp_deploy_apply.php';
        }

        return $origin . '/cloud-api/public/lp_deploy_apply.php';
    }

    public function bootstrapApplyUrlFallback(string $applyUrl): string
    {
        $origin = $this->siteOriginFromApplyUrl($applyUrl);
        $primary = $this->bootstrapApplyUrl($applyUrl);
        $alternate = $this->isOptionA()
            ? $origin . '/cloud-api/public/lp_deploy_apply.php'
            : $origin . '/lp_deploy_apply.php';

        return $alternate === $primary ? $primary : $alternate;
    }

    /**
     * Relative URL paths (from site origin) used to detect docroot mismatch over HTTP.
     *
     * @return array<string, string>
     */
    public function httpProbePaths(): array
    {
        return [
            'health_canonical' => '/api/v1/health',
            'health_legacy_prefix' => '/cloud-api/public/api/v1/health',
            'bootstrap_primary' => $this->isOptionA() ? '/lp_deploy_apply.php' : '/cloud-api/public/lp_deploy_apply.php',
        ];
    }

    private static function inferLayout(string $deployRoot, string $httpDocroot): string
    {
        $optionADocroot = CredentialLoader::toRemotePath($deployRoot, 'cloud-api/public');
        if ($httpDocroot === $optionADocroot) {
            return self::LAYOUT_OPTION_A;
        }
        if ($httpDocroot === CredentialLoader::normalizeRemoteHome($deployRoot)) {
            return self::LAYOUT_OPTION_B;
        }
        if (str_ends_with($httpDocroot, '/cloud-api/public')) {
            return self::LAYOUT_OPTION_A;
        }

        return self::LAYOUT_OPTION_B;
    }

    private static function normalizeLayout(string $layout): string
    {
        $layout = strtolower(trim($layout));
        if ($layout === 'a' || $layout === 'option-a' || $layout === 'option_a') {
            return self::LAYOUT_OPTION_A;
        }
        if ($layout === 'b' || $layout === 'option-b' || $layout === 'option_b') {
            return self::LAYOUT_OPTION_B;
        }

        return $layout === self::LAYOUT_OPTION_B ? self::LAYOUT_OPTION_B : self::LAYOUT_OPTION_A;
    }
}
