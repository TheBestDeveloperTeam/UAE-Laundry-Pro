<?php
declare(strict_types=1);
namespace LaundryPro\Api\Controllers;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
class ChemicalController
{
    public function logUsage(Request $request): Response
    {
        return Response::json(['success' => true, 'data' => []], 201);
    }
}
