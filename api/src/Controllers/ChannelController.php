<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\ChannelRepository;
use LaundryPro\Api\Services\MessagingService;

final class ChannelController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly ChannelRepository $channels,
    private readonly MessagingService $messaging,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $items = $this->channels->list();
    $this->response->success($request, ['channels' => $items], 'CHANNELS_LIST', 'channels.list');
  }

  public function store(Request $request, Container $container): void
  {
    $type = $request->input('channel_type');
    if (!in_array($type, ['sms', 'whatsapp', 'email'], true)) {
      $this->response->error($request, 'VALIDATION_ERROR', 'channels.invalid_type', 422);
      return;
    }
    $userId = (int) $container->get('auth.user_id');
    $item = $this->channels->create($request->all());
    $this->audit->log($userId, 'channels.create', 'notification_channel', (int) $item['id'], null);
    $this->response->success($request, ['channel' => $item], 'CHANNEL_CREATED', 'channels.created', 201);
  }

  public function test(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $channel = $this->channels->findById($id);
    if ($channel === null) {
      $this->response->error($request, 'NOT_FOUND', 'channels.not_found', 404);
      return;
    }
    $recipient = (string) ($request->input('recipient') ?? '');
    if ($recipient === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'channels.recipient_required', 422);
      return;
    }
    $message = $this->messaging->sendTest($channel, $recipient);
    $this->response->success($request, ['message' => $message], 'CHANNEL_TEST_SENT', 'channels.test_sent');
  }
}
