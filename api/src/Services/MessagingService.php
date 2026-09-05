<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

use LaundryPro\Api\Repositories\ChannelRepository;

final class MessagingService
{
  public function __construct(private readonly ChannelRepository $channels)
  {
  }

  /** @param array<string, mixed> $channel */
  public function sendTest(array $channel, string $recipient): array
  {
    $body = 'LaundryPro test message — order ready notification preview.';
    $template = 'order_ready';

    return $this->channels->logMessage((int) $channel['id'], $recipient, $template, $body, 'sent');
  }
}
