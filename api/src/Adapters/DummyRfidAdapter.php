<?php
declare(strict_types=1);

namespace LaundryPro\Api\Adapters;

class DummyRfidAdapter implements HardwareAdapterInterface
{
    public function connect(): bool
    {
        return true;
    }

    public function readTags(int  = 1000): array
    {
        // Mocking reading RFID tags
        return ['EPC123456789', 'EPC987654321', 'EPC111222333'];
    }

    public function disconnect(): void
    {
    }
}

