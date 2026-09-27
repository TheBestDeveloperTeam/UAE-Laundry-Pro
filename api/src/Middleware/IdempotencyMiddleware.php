<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use PDO;

final class IdempotencyMiddleware implements MiddlewareInterface
{
    public function __construct(
        private readonly PDO $pdo
    ) {}

    public function process(Request $request, RequestHandler $handler): Response
    {
        $method = $request->getMethod();

        // Idempotency applies mostly to POST and PATCH
        if (!in_array($method, ['POST', 'PATCH', 'PUT'])) {
            return $handler->handle($request);
        }

        $idempotencyKey = $request->getHeaderLine('X-Idempotency-Key');

        if (empty($idempotencyKey)) {
            // Optional: You could reject requests missing the key, or just pass them through
            return $handler->handle($request);
        }

        // Check if this key was already processed
        $stmt = $this->pdo->prepare('SELECT response_code, response_body FROM idempotency_keys WHERE id_key = ?');
        $stmt->execute([$idempotencyKey]);
        $existing = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($existing) {
            // Return the cached response
            $response = new \Slim\Psr7\Response($existing['response_code']);
            $response->getBody()->write($existing['response_body']);
            return $response->withHeader('Content-Type', 'application/json');
        }

        // Handle the request normally
        $response = $handler->handle($request);

        // Cache the response
        $responseCode = $response->getStatusCode();
        // Only cache successful or intentional responses
        if ($responseCode >= 200 && $responseCode < 500) {
            $body = (string) $response->getBody();

            $insert = $this->pdo->prepare('INSERT INTO idempotency_keys (id_key, response_code, response_body, created_at) VALUES (?, ?, ?, UTC_TIMESTAMP())');
            $insert->execute([$idempotencyKey, $responseCode, $body]);

            // Rewind body so it can be sent to client
            $response->getBody()->rewind();
        }

        return $response;
    }
}
