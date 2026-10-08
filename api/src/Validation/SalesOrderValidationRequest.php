<?php

declare(strict_types=1);

namespace LaundryPro\Api\Validation;

final class SalesOrderValidationRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'customer_id' => 'required|int',
            'lines' => 'required|array|min:1',
            'discount' => 'numeric|min:0',
            'notes' => 'string|max:500',
        ];
    }
}
