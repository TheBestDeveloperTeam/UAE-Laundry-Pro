<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Docs\OpenApiGenerator;

final class DocsController
{
  public function __construct(
    private readonly OpenApiGenerator $generator,
    private readonly string $docsUiPath,
  ) {
  }

  public function openapi(Request $request, Container $container): void
  {
    Response::json($this->generator->generate());
  }

  public function index(Request $request, Container $container): void
  {
    $indexFile = rtrim($this->docsUiPath, '/\\') . DIRECTORY_SEPARATOR . 'index.html';
    if (!is_file($indexFile)) {
      Response::json([
        'success' => false,
        'code' => 'DOCS_UNAVAILABLE',
        'message_key' => 'docs.unavailable',
        'data' => null,
        'errors' => [],
        'meta' => [],
      ], 404);
      return;
    }

    header('Content-Type: text/html; charset=utf-8');
    readfile($indexFile);
  }
}
