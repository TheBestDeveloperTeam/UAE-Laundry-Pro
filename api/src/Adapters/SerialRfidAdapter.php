<?php

declare(strict_types=1);

namespace LaundryPro\Api\Adapters;

/**
 * SerialRfidAdapter
 *
 * Communicates with physical UHF RFID Readers over Serial / COM port (e.g. COM1-COM9 on Windows,
 * or /dev/ttyUSB0 on Linux). Gracefully falls back to mock tags if port is unavailable.
 */
class SerialRfidAdapter implements HardwareAdapterInterface
{
    /** @var resource|null */
    private $handle = null;
    private readonly string $port;
    private readonly int $baudRate;
    private bool $isConnected = false;

    public function __construct(?string $port = null, int $baudRate = 9600)
    {
        $this->port = $port ?? (PHP_OS_FAMILY === 'Windows' ? 'COM3' : '/dev/ttyUSB0');
        $this->baudRate = $baudRate;
    }

    public function connect(): bool
    {
        if ($this->isConnected && is_resource($this->handle)) {
            return true;
        }

        try {
            if (PHP_OS_FAMILY === 'Windows') {
                // Configure Windows serial port via mode command
                @shell_exec(sprintf('mode %s: BAUD=%d PARITY=N DATA=8 STOP=1 to=off', escapeshellarg($this->port), $this->baudRate));
                $device = '\\\\.\\' . trim($this->port, '\\:');
                $this->handle = @fopen($device, 'r+b');
            } else {
                // Unix serial port
                @shell_exec(sprintf('stty -F %s %d cs8 -cstopb -parenb', escapeshellarg($this->port), $this->baudRate));
                $this->handle = @fopen($this->port, 'r+b');
            }

            if (is_resource($this->handle)) {
                stream_set_timeout($this->handle, 1);
                stream_set_blocking($this->handle, false);
                $this->isConnected = true;
                return true;
            }
        } catch (\Throwable) {
            $this->isConnected = false;
        }

        return false;
    }

    public function readTags(int $limit = 1000): array
    {
        if (!$this->isConnected || !is_resource($this->handle)) {
            if (!$this->connect()) {
                // Port offline or hardware disconnected: return fallback simulation
                return ['EPC-SIM-' . strtoupper(substr(md5((string) microtime(true)), 0, 8))];
            }
        }

        $tags = [];
        $startTime = time();

        while (count($tags) < $limit && (time() - $startTime) < 2) {
            $line = fgets($this->handle);
            if ($line !== false) {
                $trimmed = trim($line);
                // Standard EPC hex / alphanumeric tags are 8-32 characters
                if (preg_match('/^[A-F0-9]{8,32}$/i', $trimmed)) {
                    $tags[] = strtoupper($trimmed);
                }
            } else {
                usleep(50000); // 50ms interval
            }
        }

        return array_values(array_unique($tags));
    }

    public function disconnect(): void
    {
        if (is_resource($this->handle)) {
            @fclose($this->handle);
        }
        $this->handle = null;
        $this->isConnected = false;
    }

    public function __destruct()
    {
        $this->disconnect();
    }
}
