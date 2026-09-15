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
        private readonly ApiResponse ,
        private readonly RfidRepository ,
        private readonly HardwareAdapterInterface 
    ) {
    }

    public function scan(Request ): void
    {
         = ->all();
         = ['epc_tags'] ?? [];
        
        if (empty()) {
            // Trigger a read from the physical adapter if payload is empty
            if (->adapter->connect()) {
                 = ->adapter->readTags();
                ->adapter->disconnect();
            }
        }

        if (empty()) {
            ->response->error(, 'No RFID tags found', 422, 'NO_TAGS_FOUND');
            return;
        }

         = ->repository->processTags();

        ->response->success(, , 'TAGS_PROCESSED', 'rfid.tags_processed', 201);
    }
}

