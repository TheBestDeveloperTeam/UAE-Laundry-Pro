<?php
declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\RfidRepository;
use LaundryPro\Api\Adapters\HardwareAdapterInterface;

final class RfidController
{
    public function __construct(
        private readonly ApiResponse $response,
        private readonly RfidRepository $repository,
        private readonly HardwareAdapterInterface $adapter
    ) {
    }

    public function scan(Request $request): void
    {
        $payload = $request->all();
        $tags = $payload['epc_tags'] ?? [];

        if (empty($tags)) {
            // Trigger a read from the physical adapter if payload is empty
            if ($this->adapter->connect()) {
                $tags = $this->adapter->readTags();
                $this->adapter->disconnect();
            }
        }

        if (empty($tags)) {
            $this->response->error($request, 'No RFID tags found', 422, 'NO_TAGS_FOUND');
            return;
        }

        $result = $this->repository->processTags($tags);

        $this->response->success($request, $result, 'TAGS_PROCESSED', 'rfid.tags_processed', 201);
    }
}
