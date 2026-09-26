<?php

namespace LaundryPro\Api\Core;

use InvalidArgumentException;
use PDO;

/**
 * Validator
 * 
 * Simple rule-based request validator.
 * Rules supported: required, string, numeric, int, array, boolean, min:X, max:X, enum:A,B,C, regex:pattern
 */
class Validator
{
    private array $data;
    private array $errors = [];
    private ?PDO $db;

    public function __construct(array $data, ?PDO $db = null)
    {
        $this->data = $data;
        $this->db = $db;
    }

    /**
     * Validate data against rules.
     * Example: ['name' => 'required|string|max:255', 'age' => 'numeric|min:18']
     * 
     * @param array $rules
     * @return bool
     */
    public function validate(array $rules): bool
    {
        $this->errors = [];

        foreach ($rules as $field => $ruleString) {
            $ruleSet = explode('|', $ruleString);
            $value = $this->data[$field] ?? null;

            if (in_array('required', $ruleSet) && ($value === null || $value === '')) {
                $this->addError($field, "The {$field} field is required.");
                continue; // Skip other rules if missing
            }

            if ($value !== null && $value !== '') {
                foreach ($ruleSet as $rule) {
                    if ($rule === 'required') continue;
                    $this->applyRule($field, $value, $rule);
                }
            }
        }

        return empty($this->errors);
    }

    public function getErrors(): array
    {
        return $this->errors;
    }

    private function applyRule(string $field, $value, string $rule): void
    {
        if ($rule === 'string' && !is_string($value)) {
            $this->addError($field, "The {$field} must be a string.");
        } elseif ($rule === 'numeric' && !is_numeric($value)) {
            $this->addError($field, "The {$field} must be a number.");
        } elseif ($rule === 'int' && filter_var($value, FILTER_VALIDATE_INT) === false) {
            $this->addError($field, "The {$field} must be an integer.");
        } elseif ($rule === 'array' && !is_array($value)) {
            $this->addError($field, "The {$field} must be an array.");
        } elseif ($rule === 'boolean' && !is_bool($value) && !in_array($value, [0, 1, '0', '1'], true)) {
            $this->addError($field, "The {$field} must be a boolean.");
        } elseif (str_starts_with($rule, 'min:')) {
            $min = (float) substr($rule, 4);
            if (is_numeric($value) && $value < $min) {
                $this->addError($field, "The {$field} must be at least {$min}.");
            } elseif (is_string($value) && strlen($value) < $min) {
                $this->addError($field, "The {$field} must be at least {$min} characters.");
            } elseif (is_array($value) && count($value) < $min) {
                $this->addError($field, "The {$field} must have at least {$min} items.");
            }
        } elseif (str_starts_with($rule, 'max:')) {
            $max = (float) substr($rule, 4);
            if (is_numeric($value) && $value > $max) {
                $this->addError($field, "The {$field} must not be greater than {$max}.");
            } elseif (is_string($value) && strlen($value) > $max) {
                $this->addError($field, "The {$field} must not be greater than {$max} characters.");
            } elseif (is_array($value) && count($value) > $max) {
                $this->addError($field, "The {$field} must not have more than {$max} items.");
            }
        } elseif (str_starts_with($rule, 'enum:')) {
            $allowed = explode(',', substr($rule, 5));
            if (!in_array((string)$value, $allowed, true)) {
                $this->addError($field, "The {$field} must be one of: " . implode(', ', $allowed) . ".");
            }
        } elseif (str_starts_with($rule, 'regex:')) {
            $pattern = substr($rule, 6);
            if (preg_match($pattern, (string)$value) !== 1) {
                $this->addError($field, "The {$field} format is invalid.");
            }
        } elseif (str_starts_with($rule, 'unique:')) {
            // format: unique:table,column,ignoreId,adminIdColumn
            $params = explode(',', substr($rule, 7));
            $table = $params[0] ?? null;
            $column = $params[1] ?? $field;
            $ignoreId = $params[2] ?? null;
            $adminIdColumn = $params[3] ?? 'admin_id';

            if ($this->db && $table) {
                $sql = "SELECT 1 FROM `{$table}` WHERE `{$column}` = ?";
                $bindings = [$value];

                if ($ignoreId && $ignoreId !== 'null') {
                    $sql .= " AND id != ?";
                    $bindings[] = $ignoreId;
                }
                
                // If the context requires tenant isolation, the caller should ensure it's handled 
                // typically by passing admin_id to the rule like unique:users,email,null,123
                if (count($params) >= 5) {
                   $sql .= " AND `{$adminIdColumn}` = ?";
                   $bindings[] = $params[4];
                }

                $stmt = $this->db->prepare($sql);
                $stmt->execute($bindings);
                if ($stmt->fetchColumn()) {
                    $this->addError($field, "The {$field} has already been taken.");
                }
            }
        }
    }

    private function addError(string $field, string $message): void
    {
        if (!isset($this->errors[$field])) {
            $this->errors[$field] = [];
        }
        $this->errors[$field][] = $message;
    }
}
