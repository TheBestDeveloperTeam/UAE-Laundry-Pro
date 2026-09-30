<?php

declare(strict_types=1);

require_once __DIR__ . '/../api/bootstrap.php';
require_once __DIR__ . '/../api/routes/api.php';

use LaundryPro\Api\Core\Router;
use LaundryPro\Api\Core\RouteRegistry;
use LaundryPro\Api\Docs\OpenApiGenerator;
use LaundryPro\Api\Docs\Schemas\ApiSchemas;

function array_to_yaml(mixed $data, int $indent = 0): string
{
    $sp = str_repeat('  ', $indent);
    if (is_null($data)) {
        return "null\n";
    }
    if (is_bool($data)) {
        return ($data ? 'true' : 'false') . "\n";
    }
    if (is_numeric($data)) {
        return $data . "\n";
    }
    if (is_string($data)) {
        if ($data === '' || preg_match('/[:\[\]\{\},&*#?|\-<>=!%@`\n\r]/', $data) || in_array(strtolower($data), ['true', 'false', 'null', 'yes', 'no'])) {
            return '"' . addcslashes($data, "\"\t\r\n\\") . "\"\n";
        }
        return $data . "\n";
    }
    if (is_array($data)) {
        if (empty($data)) {
            return "{}\n";
        }
        $isList = array_is_list($data);
        $out = '';
        if ($isList) {
            foreach ($data as $item) {
                if (is_array($item)) {
                    $itemYaml = array_to_yaml($item, $indent + 1);
                    $trimmed = ltrim($itemYaml);
                    $out .= $sp . "- " . $trimmed;
                } else {
                    $out .= $sp . "- " . array_to_yaml($item, 0);
                }
            }
        } else {
            foreach ($data as $key => $val) {
                $safeKey = is_string($key) && preg_match('/[:\s]/', $key) ? '"' . $key . '"' : (string)$key;
                if (is_array($val)) {
                    if (empty($val)) {
                        $out .= $sp . $safeKey . ": {}\n";
                    } elseif (array_is_list($val)) {
                        $out .= $sp . $safeKey . ":\n" . array_to_yaml($val, $indent + 1);
                    } else {
                        $out .= $sp . $safeKey . ":\n" . array_to_yaml($val, $indent + 1);
                    }
                } else {
                    $out .= $sp . $safeKey . ": " . array_to_yaml($val, 0);
                }
            }
        }
        return $out;
    }
    return (string)$data . "\n";
}

$router = new Router();
register_api_routes($router);

$localGen = new OpenApiGenerator(
    'LaundryPro UAE — Local Station API',
    '2.0.0',
    'http://127.0.0.1:8080'
);
$localSpec = $localGen->generate();

// Write local JSON and YAML
$docsDir = __DIR__ . '/../docs/swagger';
if (!is_dir($docsDir)) {
    mkdir($docsDir, 0777, true);
}
$apiDocsDir = __DIR__ . '/../api/docs';
if (!is_dir($apiDocsDir)) {
    mkdir($apiDocsDir, 0777, true);
}

file_put_contents($apiDocsDir . '/openapi.json', json_encode($localSpec, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
file_put_contents($docsDir . '/local-api.yaml', array_to_yaml($localSpec));
echo "Generated local-api.yaml and openapi.json (" . count($localSpec['paths']) . " paths)\n";

// Now build Cloud API OpenAPI Specification
$cloudSpec = [
    'openapi' => '3.0.3',
    'info' => [
        'title' => 'LaundryPro UAE — Cloud Central Multi-Tenant API',
        'version' => '2.0.0',
        'description' => 'Authoritative Cloud Multi-Tenant REST API for Central Super-Admin, Licensing, and Franchise Sync Ingestion.',
        'contact' => [
            'name' => 'LaundryPro Cloud Engineering',
            'email' => 'support@magnificentsolution.co.in'
        ],
    ],
    'servers' => [
        ['url' => 'https://api.cloud.laundrypro.ae/v1', 'description' => 'Production Cloud Gateway'],
        ['url' => 'http://127.0.0.1:8081', 'description' => 'Local Cloud Staging / Dev'],
    ],
    'tags' => [
        ['name' => 'Platform', 'description' => 'Health checks and telemetry endpoints'],
        ['name' => 'Tenants', 'description' => 'Multi-tenant organization registration and onboarding'],
        ['name' => 'Sync', 'description' => 'Outbox/Inbox delta synchronization pipeline'],
        ['name' => 'License', 'description' => '3-Way hardware handshake and license activation'],
        ['name' => 'Reports', 'description' => 'Cross-tenant aggregation and executive reporting'],
        ['name' => 'Backup', 'description' => 'Encrypted snapshot storage and disaster recovery'],
        ['name' => 'SuperAdmin', 'description' => 'Central control plane operations'],
    ],
    'paths' => [
        '/api/v1/health' => [
            'get' => [
                'tags' => ['Platform'],
                'summary' => 'Cloud system health status',
                'operationId' => 'cloudHealthCheck',
                'security' => [],
                'responses' => [
                    '200' => [
                        'description' => 'System operational',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/businesses/register' => [
            'post' => [
                'tags' => ['Tenants'],
                'summary' => 'Register new tenant business node',
                'operationId' => 'registerTenantBusiness',
                'security' => [],
                'requestBody' => [
                    'required' => true,
                    'content' => [
                        'application/json' => [
                            'schema' => [
                                'type' => 'object',
                                'required' => ['name', 'cloud_token'],
                                'properties' => [
                                    'name' => ['type' => 'string'],
                                    'cloud_token' => ['type' => 'string'],
                                    'trade_license_no' => ['type' => 'string'],
                                    'contact_email' => ['type' => 'string', 'format' => 'email'],
                                    'contact_phone' => ['type' => 'string'],
                                    'country_code' => ['type' => 'string', 'default' => 'AE'],
                                    'city' => ['type' => 'string', 'default' => 'Dubai'],
                                    'max_branches' => ['type' => 'integer', 'default' => 1],
                                    'max_devices' => ['type' => 'integer', 'default' => 1]
                                ]
                            ]
                        ]
                    ]
                ],
                'responses' => [
                    '201' => [
                        'description' => 'Tenant registered successfully',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ],
                    '400' => ['description' => 'Validation error']
                ]
            ]
        ],
        '/api/v1/sync/push' => [
            'post' => [
                'tags' => ['Sync'],
                'summary' => 'Inbound delta sync batch from local node to cloud',
                'operationId' => 'syncPushBatch',
                'security' => [['cloudTokenAuth' => []]],
                'requestBody' => [
                    'required' => true,
                    'content' => [
                        'application/json' => [
                            'schema' => [
                                'type' => 'object',
                                'required' => ['batch'],
                                'properties' => [
                                    'batch' => [
                                        'type' => 'array',
                                        'items' => [
                                            'type' => 'object',
                                            'required' => ['entity_type', 'entity_uuid', 'operation', 'payload'],
                                            'properties' => [
                                                'entity_type' => ['type' => 'string'],
                                                'entity_uuid' => ['type' => 'string', 'format' => 'uuid'],
                                                'entity_local_id' => ['type' => 'integer'],
                                                'operation' => ['type' => 'string', 'enum' => ['INSERT', 'UPDATE', 'DELETE', 'create', 'update', 'delete']],
                                                'payload' => ['type' => 'object'],
                                                'entity_version' => ['type' => 'integer'],
                                                'source_umac' => ['type' => 'string']
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                'responses' => [
                    '200' => [
                        'description' => 'Batch processed successfully with accepted/rejected list',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/sync/pull' => [
            'get' => [
                'tags' => ['Sync'],
                'summary' => 'Extract cloud changes for local workstation inbox',
                'operationId' => 'syncPullBatch',
                'security' => [['cloudTokenAuth' => []]],
                'parameters' => [
                    [
                        'name' => 'cursor',
                        'in' => 'query',
                        'required' => false,
                        'schema' => ['type' => 'string'],
                        'description' => 'ISO8601 timestamp cursor or sequence ID'
                    ],
                    [
                        'name' => 'limit',
                        'in' => 'query',
                        'required' => false,
                        'schema' => ['type' => 'integer', 'default' => 100],
                        'description' => 'Max number of changes to return'
                    ]
                ],
                'responses' => [
                    '200' => [
                        'description' => 'Changes returned since cursor',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/sync/backup' => [
            'post' => [
                'tags' => ['Backup'],
                'summary' => 'Upload encrypted database backup snapshot to cloud',
                'operationId' => 'uploadBackupSnapshot',
                'security' => [['cloudTokenAuth' => []]],
                'requestBody' => [
                    'required' => true,
                    'content' => [
                        'application/json' => [
                            'schema' => [
                                'type' => 'object',
                                'required' => ['backup_data'],
                                'properties' => [
                                    'backup_data' => ['type' => 'string', 'format' => 'binary', 'description' => 'Base64 encoded encrypted SQL backup'],
                                    'filename' => ['type' => 'string'],
                                    'checksum' => ['type' => 'string']
                                ]
                            ]
                        ]
                    ]
                ],
                'responses' => [
                    '200' => [
                        'description' => 'Backup received and stored',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/reports/aggregation' => [
            'get' => [
                'tags' => ['Reports'],
                'summary' => 'Central multi-tenant revenue and transaction metrics',
                'operationId' => 'centralizedReports',
                'security' => [['bearerAuth' => []]],
                'parameters' => [
                    ['name' => 'from', 'in' => 'query', 'required' => false, 'schema' => ['type' => 'string', 'format' => 'date']],
                    ['name' => 'to', 'in' => 'query', 'required' => false, 'schema' => ['type' => 'string', 'format' => 'date']],
                    ['name' => 'tenant_id', 'in' => 'query', 'required' => false, 'schema' => ['type' => 'integer']]
                ],
                'responses' => [
                    '200' => [
                        'description' => 'Aggregated financial metrics',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/license/validate' => [
            'post' => [
                'tags' => ['License'],
                'summary' => '3-Way handshake license activation and hardware verification',
                'operationId' => 'validateLicenseKey',
                'security' => [],
                'requestBody' => [
                    'required' => true,
                    'content' => [
                        'application/json' => [
                            'schema' => [
                                'type' => 'object',
                                'required' => ['license_key', 'umac'],
                                'properties' => [
                                    'license_key' => ['type' => 'string'],
                                    'umac' => ['type' => 'string', 'description' => 'SHA-256 hardware fingerprint hash'],
                                    'workstation_name' => ['type' => 'string'],
                                    'app_version' => ['type' => 'string']
                                ]
                            ]
                        ]
                    ]
                ],
                'responses' => [
                    '200' => [
                        'description' => 'License verification result with plan parameters and cryptographic signature',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ],
                    '403' => ['description' => 'License expired, revoked, or UMAC device limit exceeded']
                ]
            ]
        ],
        '/api/v1/tenant/profile' => [
            'get' => [
                'tags' => ['Tenants'],
                'summary' => 'Get authenticated tenant business profile',
                'operationId' => 'getTenantProfile',
                'security' => [['bearerAuth' => []]],
                'responses' => [
                    '200' => [
                        'description' => 'Tenant profile details',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/tenant/customers' => [
            'get' => [
                'tags' => ['Tenants'],
                'summary' => 'List tenant customers',
                'operationId' => 'listTenantCustomers',
                'security' => [['bearerAuth' => []]],
                'parameters' => [
                    ['name' => 'q', 'in' => 'query', 'required' => false, 'schema' => ['type' => 'string']],
                    ['name' => 'page', 'in' => 'query', 'required' => false, 'schema' => ['type' => 'integer']],
                    ['name' => 'limit', 'in' => 'query', 'required' => false, 'schema' => ['type' => 'integer']]
                ],
                'responses' => [
                    '200' => [
                        'description' => 'Paginated customer list',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ],
            'post' => [
                'tags' => ['Tenants'],
                'summary' => 'Register customer under tenant',
                'operationId' => 'createTenantCustomer',
                'security' => [['bearerAuth' => []]],
                'requestBody' => [
                    'required' => true,
                    'content' => [
                        'application/json' => [
                            'schema' => [
                                'type' => 'object',
                                'required' => ['name', 'phone'],
                                'properties' => [
                                    'name' => ['type' => 'string'],
                                    'phone' => ['type' => 'string'],
                                    'email' => ['type' => 'string'],
                                    'address' => ['type' => 'string'],
                                    'emirate' => ['type' => 'string'],
                                    'credit_limit' => ['type' => 'number']
                                ]
                            ]
                        ]
                    ]
                ],
                'responses' => [
                    '201' => [
                        'description' => 'Customer created',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/tenant/catalog/services' => [
            'get' => [
                'tags' => ['Tenants'],
                'summary' => 'List catalog services for tenant',
                'operationId' => 'listTenantServices',
                'security' => [['bearerAuth' => []]],
                'responses' => [
                    '200' => [
                        'description' => 'Service catalog list',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ],
            'post' => [
                'tags' => ['Tenants'],
                'summary' => 'Add service to tenant catalog',
                'operationId' => 'createTenantService',
                'security' => [['bearerAuth' => []]],
                'requestBody' => [
                    'required' => true,
                    'content' => [
                        'application/json' => [
                            'schema' => [
                                'type' => 'object',
                                'required' => ['name', 'price'],
                                'properties' => [
                                    'name' => ['type' => 'string'],
                                    'service_code' => ['type' => 'string'],
                                    'price' => ['type' => 'number'],
                                    'turnaround_hours' => ['type' => 'integer']
                                ]
                            ]
                        ]
                    ]
                ],
                'responses' => [
                    '201' => [
                        'description' => 'Service created',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/tenant/orders' => [
            'get' => [
                'tags' => ['Tenants'],
                'summary' => 'List tenant sales orders',
                'operationId' => 'listTenantOrders',
                'security' => [['bearerAuth' => []]],
                'parameters' => [
                    ['name' => 'status', 'in' => 'query', 'schema' => ['type' => 'string']],
                    ['name' => 'page', 'in' => 'query', 'schema' => ['type' => 'integer']],
                    ['name' => 'limit', 'in' => 'query', 'schema' => ['type' => 'integer']]
                ],
                'responses' => [
                    '200' => [
                        'description' => 'Order list',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ],
            'post' => [
                'tags' => ['Tenants'],
                'summary' => 'Create sales order with UAE 5% VAT',
                'operationId' => 'createTenantOrder',
                'security' => [['bearerAuth' => []]],
                'requestBody' => [
                    'required' => true,
                    'content' => [
                        'application/json' => [
                            'schema' => [
                                'type' => 'object',
                                'required' => ['items'],
                                'properties' => [
                                    'customer_id' => ['type' => 'integer'],
                                    'source_branch' => ['type' => 'string'],
                                    'items' => [
                                        'type' => 'array',
                                        'items' => [
                                            'type' => 'object',
                                            'required' => ['item_name', 'unit_price'],
                                            'properties' => [
                                                'service_id' => ['type' => 'integer'],
                                                'item_name' => ['type' => 'string'],
                                                'quantity' => ['type' => 'integer'],
                                                'unit_price' => ['type' => 'number'],
                                                'notes' => ['type' => 'string']
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                'responses' => [
                    '201' => [
                        'description' => 'Order created with VAT breakdown',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ],
        '/api/v1/tenant/reports/summary' => [
            'get' => [
                'tags' => ['Reports'],
                'summary' => 'Get tenant sales, customer and VAT metrics',
                'operationId' => 'getTenantReportsSummary',
                'security' => [['bearerAuth' => []]],
                'responses' => [
                    '200' => [
                        'description' => 'Summary financial and operational metrics',
                        'content' => ['application/json' => ['schema' => ['$ref' => '#/components/schemas/ApiEnvelope']]]
                    ]
                ]
            ]
        ]
    ],
    'components' => [
        'securitySchemes' => [
            'bearerAuth' => [
                'type' => 'http',
                'scheme' => 'bearer',
                'bearerFormat' => 'JWT',
            ],
            'cloudTokenAuth' => [
                'type' => 'apiKey',
                'in' => 'header',
                'name' => 'Authorization',
                'description' => 'Bearer <cloud_token> assigned to the tenant'
            ]
        ],
        'schemas' => ApiSchemas::components()['schemas']
    ]
];

// Merge all 178 Local endpoints into Cloud API Paths (100% domain and route parity)
foreach ($localSpec['paths'] as $path => $methods) {
    if (!isset($cloudSpec['paths'][$path])) {
        $cloudSpec['paths'][$path] = [];
    }
    foreach ($methods as $method => $op) {
        $cloudOp = $op;
        $cloudOp['operationId'] = 'cloud_' . ($op['operationId'] ?? (strtolower($method) . str_replace('/', '_', $path)));
        $cloudOp['security'] = [['bearerAuth' => []], ['cloudTokenAuth' => []]];
        $cloudSpec['paths'][$path][$method] = $cloudOp;
    }
}

// Merge tags
$cloudTagsMap = [];
foreach ($cloudSpec['tags'] as $t) {
    $cloudTagsMap[$t['name']] = $t;
}
foreach ($localSpec['tags'] as $t) {
    if (!isset($cloudTagsMap[$t['name']])) {
        $cloudTagsMap[$t['name']] = $t;
    }
}
$cloudSpec['tags'] = array_values($cloudTagsMap);

// Create cloud docs directory if not exists
$cloudDocsDir = __DIR__ . '/../cloud-api/docs';
if (!is_dir($cloudDocsDir)) {
    mkdir($cloudDocsDir, 0777, true);
}

// Write Cloud OpenAPI YAML and JSON
file_put_contents($docsDir . '/cloud-api.yaml', array_to_yaml($cloudSpec));
file_put_contents($docsDir . '/cloud-api.json', json_encode($cloudSpec, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
file_put_contents($cloudDocsDir . '/openapi.json', json_encode($cloudSpec, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
echo "Generated cloud-api.yaml and cloud-api.json (" . count($cloudSpec['paths']) . " paths)\n";

// Now build Unified OpenAPI Specification combining Local and Cloud
$unifiedPaths = [];
foreach ($localSpec['paths'] as $path => $item) {
    $unifiedPaths['/local' . $path] = $item;
}
foreach ($cloudSpec['paths'] as $path => $item) {
    $unifiedPaths['/cloud' . $path] = $item;
}

$unifiedTags = array_merge($localSpec['tags'], $cloudSpec['tags']);
$tagMap = [];
foreach ($unifiedTags as $t) {
    $tagMap[$t['name']] = $t;
}

$unifiedSpec = [
    'openapi' => '3.0.3',
    'info' => [
        'title' => 'LaundryPro UAE — Unified API Specification',
        'version' => '2.0.0',
        'description' => "Complete unified specification for LaundryPro UAE enterprise system.\nIncludes both Local Workstation API endpoints (/local/api/v1/...) and Cloud Multi-Tenant Gateway endpoints (/cloud/api/v1/...).",
        'contact' => [
            'name' => 'LaundryPro Architecture Team',
            'email' => 'dev@magnificentsolution.co.in'
        ],
        'license' => [
            'name' => 'Proprietary',
            'url' => 'https://laundrypro.ae/license'
        ]
    ],
    'servers' => [
        ['url' => 'http://127.0.0.1:8080', 'description' => 'Local Workstation API'],
        ['url' => 'https://api.cloud.laundrypro.ae/v1', 'description' => 'Cloud Central Multi-Tenant API'],
        ['url' => 'http://127.0.0.1:8081', 'description' => 'Local Cloud Dev Server'],
    ],
    'tags' => array_values($tagMap),
    'paths' => $unifiedPaths,
    'components' => [
        'securitySchemes' => [
            'bearerAuth' => [
                'type' => 'http',
                'scheme' => 'bearer',
                'bearerFormat' => 'JWT',
            ],
            'installToken' => [
                'type' => 'apiKey',
                'in' => 'header',
                'name' => 'X-Install-Token',
            ],
            'cloudTokenAuth' => [
                'type' => 'apiKey',
                'in' => 'header',
                'name' => 'Authorization',
                'description' => 'Bearer <cloud_token>'
            ]
        ],
        'schemas' => ApiSchemas::components()['schemas']
    ]
];

file_put_contents($docsDir . '/UNIFIED_SWAGGER.yaml', array_to_yaml($unifiedSpec));
echo "Generated UNIFIED_SWAGGER.yaml (" . count($unifiedSpec['paths']) . " total unified paths)\n";
echo "Swagger generation complete!\n";
