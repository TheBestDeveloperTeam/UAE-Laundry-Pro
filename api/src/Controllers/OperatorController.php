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
        private readonly ApiResponse ,
        private readonly OperatorRepository 
    ) {
    }

    public function listCertifications(Request ): void
    {
         = ->repository->getCertifications();
        ->response->success(, ['certifications' => ], 'CERTIFICATIONS_LIST', 'operator.list_certifications', 200);
    }

    public function certify(Request , Container ): void
    {
         = (int) ->route('id');
         = ->all();

        if (!isset(['certification_name'], ['issued_at'], ['expires_at'])) {
            ->response->error(, 'Missing required fields', 422, 'VALIDATION_ERROR');
            return;
        }

         = ->repository->certify(
            ,
            ['certification_name'],
            ['issued_at'],
            ['expires_at']
        );

        ->response->success(, ['id' => ], 'CERTIFIED', 'operator.certified', 201);
    }
}

