<?php

declare(strict_types=1);

namespace LaundryPro\Api\Validation;

use InvalidArgumentException;
use LaundryPro\Api\Core\Validator;
use PDO;

abstract class FormRequest
{
    protected array $data;
    protected ?PDO $db;
    protected array $errors = [];

    public function __construct(array $data, ?PDO $db = null)
    {
        $this->data = $data;
        $this->db = $db;
    }

    /**
     * Define the validation rules for the request.
     *
     * @return array<string, string>
     */
    abstract public function rules(): array;

    /**
     * Validate the current request data.
     *
     * @throws InvalidArgumentException when validation fails
     */
    public function validate(): array
    {
        $validator = new Validator($this->data, $this->db);
        if (!$validator->validate($this->rules())) {
            $this->errors = $validator->getErrors();
            throw new InvalidArgumentException(json_encode($this->errors, JSON_UNESCAPED_UNICODE));
        }

        return $this->validated();
    }

    public function validated(): array
    {
        $allowedKeys = array_keys($this->rules());
        return array_intersect_key($this->data, array_flip($allowedKeys));
    }

    public function getErrors(): array
    {
        return $this->errors;
    }
}
