<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\RoleRepository;

final class RoleController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly RoleRepository $roles,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $roles = $this->roles->findAll();
    
    // Parse permissions JSON for output
    foreach ($roles as &$role) {
      $role['permissions'] = json_decode($role['permissions'], true);
    }
    
    $this->response->success($request, ['roles' => $roles], 'ROLES_FETCHED');
  }

  public function store(Request $request, Container $container): void
  {
    $name = trim((string) $request->input('name', ''));
    $permissions = $request->input('permissions', []);

    if ($name === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'Name is required', 422);
      return;
    }

    try {
      $id = $this->roles->create($name, $permissions);
      $role = $this->roles->findById($id);
      $role['permissions'] = json_decode($role['permissions'], true);
      $this->response->success($request, ['role' => $role], 'ROLE_CREATED', 'Role created successfully', 201);
    } catch (\PDOException $e) {
      if ($e->getCode() === '23000') {
        $this->response->error($request, 'DUPLICATE_ROLE', 'Role name already exists', 409);
      } else {
        throw $e;
      }
    }
  }

  public function update(Request $request, Container $container, array $args): void
  {
    $id = (int) $args['id'];
    $name = trim((string) $request->input('name', ''));
    $permissions = $request->input('permissions');

    if ($name === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'Name is required', 422);
      return;
    }

    $existing = $this->roles->findById($id);
    if ($existing === null) {
      $this->response->error($request, 'NOT_FOUND', 'Role not found', 404);
      return;
    }

    // Preserve permissions if not provided
    if ($permissions === null) {
      $permissions = json_decode($existing['permissions'], true);
    }

    try {
      $this->roles->update($id, $name, $permissions);
      $role = $this->roles->findById($id);
      $role['permissions'] = json_decode($role['permissions'], true);
      $this->response->success($request, ['role' => $role], 'ROLE_UPDATED', 'Role updated successfully');
    } catch (\PDOException $e) {
      if ($e->getCode() === '23000') {
        $this->response->error($request, 'DUPLICATE_ROLE', 'Role name already exists', 409);
      } else {
        throw $e;
      }
    }
  }
}

