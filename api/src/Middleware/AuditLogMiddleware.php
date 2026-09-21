<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use LaundryPro\Api\Repositories\AuditLogRepository;

final class AuditLogMiddleware implements MiddlewareInterface
{
    public function __construct(
        private readonly AuditLogRepository $auditLogs
    ) {}

    public function process(Request $request, RequestHandler $handler): Response
    {
        $response = $handler->handle($request);
        
        $method = $request->getMethod();
        
        // We only care about state-changing methods
        if (in_array($method, ['POST', 'PUT', 'PATCH', 'DELETE'])) {
            $userId = $request->getAttribute('user_id'); // Assuming auth middleware sets this
            $path = $request->getUri()->getPath();
            
            // Basic extraction (could be refined based on route patterns)
            $entityType = 'http_route';
            $entityId = null;
            $action = $method;

            // Extract entity and ID if possible, e.g., /api/invoices/123
            $parts = explode('/', trim($path, '/'));
            if (count($parts) >= 2 && $parts[0] === 'api') {
                $entityType = $parts[1];
                if (isset($parts[2]) && is_numeric($parts[2])) {
                    $entityId = (int)$parts[2];
                }
            }

            // Capture payload (be careful not to log sensitive data like passwords)
            $payloadArray = $request->getParsedBody();
            if (is_array($payloadArray)) {
                unset($payloadArray['password']);
                unset($payloadArray['password_confirmation']);
                unset($payloadArray['old_password']);
            }
            $payload = $payloadArray ? json_encode($payloadArray) : null;
            
            // Log it
            try {
                $this->auditLogs->log(
                    $userId,
                    $action,
                    $entityType,
                    $entityId,
                    $payload
                );
            } catch (\Exception $e) {
                // We typically shouldn't let an audit log failure break the main request
                // unless it's a strict compliance requirement. 
                error_log("Audit log failed: " . $e->getMessage());
            }
        }

        return $response;
    }
}
