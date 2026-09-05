<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\CatalogRepository;
use RuntimeException;

final class CatalogController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly CatalogRepository $catalog,
  ) {
  }

  public function services(Request $request, Container $container): void
  {
    $parentId = $request->query('parent_id');
    $items = $this->catalog->listServices($parentId !== null ? (int) $parentId : null);
    $this->response->success($request, ['services' => $items], 'SERVICES_LIST', 'catalog.services_list');
  }

  public function showService(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->catalog->findService($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'catalog.service_not_found', 404);
      return;
    }
    $this->response->success($request, ['service' => $item], 'SERVICE_DETAIL', 'catalog.service_detail');
  }

  public function createService(Request $request, Container $container): void
  {
    $name = $request->input('name');
    if (!is_string($name) || trim($name) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'catalog.validation_failed', 422);
      return;
    }

    try {
      $item = $this->catalog->createService($request->all());
      $this->response->success($request, ['service' => $item], 'SERVICE_CREATED', 'catalog.service_created', 201);
    } catch (RuntimeException $e) {
      if ($e->getMessage() === 'HIERARCHY_CYCLE') {
        $this->response->error($request, 'HIERARCHY_CYCLE', 'catalog.hierarchy_cycle', 422);
        return;
      }
      throw $e;
    }
  }

  public function updateService(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    try {
      $item = $this->catalog->updateService($id, $request->all());
      if ($item === null) {
        $this->response->error($request, 'NOT_FOUND', 'catalog.service_not_found', 404);
        return;
      }
      $this->response->success($request, ['service' => $item], 'SERVICE_UPDATED', 'catalog.service_updated');
    } catch (RuntimeException $e) {
      if ($e->getMessage() === 'HIERARCHY_CYCLE') {
        $this->response->error($request, 'HIERARCHY_CYCLE', 'catalog.hierarchy_cycle', 422);
        return;
      }
      throw $e;
    }
  }

  public function products(Request $request, Container $container): void
  {
    $barcode = $request->query('barcode');
    $parentId = $request->query('parent_id');
    $items = $this->catalog->listProducts(
      $parentId !== null ? (int) $parentId : null,
      is_string($barcode) ? $barcode : null,
    );
    $this->response->success($request, ['products' => $items], 'PRODUCTS_LIST', 'catalog.products_list');
  }

  public function showProduct(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    $item = $this->catalog->findProduct($id);
    if ($item === null) {
      $this->response->error($request, 'NOT_FOUND', 'catalog.product_not_found', 404);
      return;
    }
    $this->response->success($request, ['product' => $item], 'PRODUCT_DETAIL', 'catalog.product_detail');
  }

  public function createProduct(Request $request, Container $container): void
  {
    $name = $request->input('name');
    if (!is_string($name) || trim($name) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'catalog.validation_failed', 422);
      return;
    }

    try {
      $item = $this->catalog->createProduct($request->all());
      $this->response->success($request, ['product' => $item], 'PRODUCT_CREATED', 'catalog.product_created', 201);
    } catch (RuntimeException $e) {
      if ($e->getMessage() === 'HIERARCHY_CYCLE') {
        $this->response->error($request, 'HIERARCHY_CYCLE', 'catalog.hierarchy_cycle', 422);
        return;
      }
      throw $e;
    }
  }

  public function updateProduct(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    try {
      $item = $this->catalog->updateProduct($id, $request->all());
      if ($item === null) {
        $this->response->error($request, 'NOT_FOUND', 'catalog.product_not_found', 404);
        return;
      }
      $this->response->success($request, ['product' => $item], 'PRODUCT_UPDATED', 'catalog.product_updated');
    } catch (RuntimeException $e) {
      if ($e->getMessage() === 'HIERARCHY_CYCLE') {
        $this->response->error($request, 'HIERARCHY_CYCLE', 'catalog.hierarchy_cycle', 422);
        return;
      }
      throw $e;
    }
  }

  public function serviceProducts(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    if ($this->catalog->findService($id) === null) {
      $this->response->error($request, 'NOT_FOUND', 'catalog.service_not_found', 404);
      return;
    }
    $items = $this->catalog->listServiceProducts($id);
    $this->response->success($request, ['products' => $items], 'SERVICE_PRODUCTS', 'catalog.service_products');
  }

  public function attachServiceProduct(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    try {
      $result = $this->catalog->attachProduct($id, $request->all());
      $this->response->success($request, $result, 'SERVICE_PRODUCT_ATTACHED', 'catalog.service_product_attached', 201);
    } catch (RuntimeException $e) {
      if ($e->getMessage() === 'NOT_FOUND') {
        $this->response->error($request, 'NOT_FOUND', 'catalog.service_not_found', 404);
        return;
      }
      $this->response->error($request, 'VALIDATION_ERROR', 'catalog.validation_failed', 422);
    }
  }

  public function detachServiceProduct(Request $request, Container $container): void
  {
    $serviceId = (int) $request->route('id', 0);
    $productId = (int) $request->route('productId', 0);
    if (!$this->catalog->detachProduct($serviceId, $productId)) {
      $this->response->error($request, 'NOT_FOUND', 'catalog.map_not_found', 404);
      return;
    }
    $this->response->success($request, [], 'SERVICE_PRODUCT_DETACHED', 'catalog.service_product_detached');
  }

  public function serviceModifiers(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    if ($this->catalog->findService($id) === null) {
      $this->response->error($request, 'NOT_FOUND', 'catalog.service_not_found', 404);
      return;
    }
    $items = $this->catalog->listServiceModifiers($id);
    $this->response->success($request, ['modifiers' => $items], 'SERVICE_MODIFIERS', 'catalog.service_modifiers');
  }

  public function createServiceModifier(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    try {
      $item = $this->catalog->createServiceModifier($id, $request->all());
      $this->response->success($request, ['modifier' => $item], 'SERVICE_MODIFIER_CREATED', 'catalog.service_modifier_created', 201);
    } catch (RuntimeException $e) {
      if ($e->getMessage() === 'NOT_FOUND') {
        $this->response->error($request, 'NOT_FOUND', 'catalog.service_not_found', 404);
        return;
      }
      $this->response->error($request, 'VALIDATION_ERROR', 'catalog.validation_failed', 422);
    }
  }

  public function productModifiers(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    if ($this->catalog->findProduct($id) === null) {
      $this->response->error($request, 'NOT_FOUND', 'catalog.product_not_found', 404);
      return;
    }
    $items = $this->catalog->listProductModifiers($id);
    $this->response->success($request, ['modifiers' => $items], 'PRODUCT_MODIFIERS', 'catalog.product_modifiers');
  }

  public function createProductModifier(Request $request, Container $container): void
  {
    $id = (int) $request->route('id', 0);
    try {
      $item = $this->catalog->createProductModifier($id, $request->all());
      $this->response->success($request, ['modifier' => $item], 'PRODUCT_MODIFIER_CREATED', 'catalog.product_modifier_created', 201);
    } catch (RuntimeException $e) {
      if ($e->getMessage() === 'NOT_FOUND') {
        $this->response->error($request, 'NOT_FOUND', 'catalog.product_not_found', 404);
        return;
      }
      $this->response->error($request, 'VALIDATION_ERROR', 'catalog.validation_failed', 422);
    }
  }
}
