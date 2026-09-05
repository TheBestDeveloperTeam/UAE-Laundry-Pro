<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\NotificationRepository;

final class NotificationController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly NotificationRepository $notifications,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $unread = $request->query('unread');
    $unreadOnly = $unread === '1' || $unread === 'true';
    $items = $this->notifications->list($unreadOnly);
    $this->response->success($request, ['notifications' => $items], 'NOTIFICATIONS_LIST', 'notifications.list');
  }

  public function show(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->notifications->findById($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'notifications.not_found', 404);
      return;
    }
    $this->response->success($request, ['notification' => $item], 'NOTIFICATION_DETAIL', 'notifications.detail');
  }

  public function markRead(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $userId = (int) $container->get('auth.user_id');
    $item = $this->notifications->markRead($id, $userId);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'notifications.not_found', 404);
      return;
    }
    $this->response->success($request, ['notification' => $item], 'NOTIFICATION_READ', 'notifications.marked_read');
  }

  public function markAllRead(Request $request, Container $container): void
  {
    $userId = (int) $container->get('auth.user_id');
    $count = $this->notifications->markAllRead($userId);
    $this->response->success($request, ['marked_count' => $count], 'NOTIFICATIONS_READ_ALL', 'notifications.all_marked_read');
  }

  public function generate(Request $request, Container $container): void
  {
    $userId = (int) $container->get('auth.user_id');
    $title = $request->input('title');
    if (is_string($title) && $title !== '') {
      $notification = $this->notifications->create($request->all());
      $this->audit->log($userId, 'notifications.create', 'notification', (int) $notification['id'], null);
      $this->response->success($request, ['notification' => $notification], 'NOTIFICATION_CREATED', 'notifications.created', 201);
      return;
    }

    $created = $this->notifications->generateAlerts();
    $this->audit->log($userId, 'notifications.generate', 'notification', null, json_encode(['created_count' => count($created)]));
    $this->response->success($request, ['created' => $created, 'created_count' => count($created)], 'NOTIFICATIONS_GENERATED', 'notifications.generated');
  }
}
