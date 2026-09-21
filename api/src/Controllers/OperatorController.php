<?php
declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\OperatorRepository;
use LaundryPro\Api\Core\Container;

final class OperatorController
{
    public function __construct(
        private readonly ApiResponse $response,
        private readonly OperatorRepository $repository
    ) {
    }

    public function listCertifications(Request $request): void
    {
        $certifications = $this->repository->getCertifications();
        $this->response->success($request, ['certifications' => $certifications], 'CERTIFICATIONS_LIST', 'operator.list_certifications', 200);
    }

    public function certify(Request $request, Container $container): void
    {
        $id = (int) $request->route('id');
        $payload = $request->all();

        if (!isset($payload['certification_name'], $payload['issued_at'], $payload['expires_at'])) {
            $this->response->error($request, 'Missing required fields', 422, 'VALIDATION_ERROR');
            return;
        }

        $logId = $this->repository->certify(
            $id,
            $payload['certification_name'],
            $payload['issued_at'],
            $payload['expires_at']
        );

        $this->response->success($request, ['id' => $logId], 'CERTIFIED', 'operator.certified', 201);
    }
}
