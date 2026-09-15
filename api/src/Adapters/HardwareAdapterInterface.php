<?php
declare(strict_types=1);

namespace LaundryPro\Api\Adapters;

interface HardwareAdapterInterface
{
    public function connect(): bool;
    public function readTags(int  = 1000): array;
    public function disconnect(): void;
}

