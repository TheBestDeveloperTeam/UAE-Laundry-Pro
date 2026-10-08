<?php

declare(strict_types=1);

namespace LaundryPro\Api\Validation;

final class CustomerValidationRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => 'required|string|min:2|max:255',
            'phone' => 'required|string|min:7|max:30',
            'email' => 'string|max:150',
            'address_line1' => 'string|max:255',
            'customer_type' => 'enum:personal,professional,walk_in',
            'credit_limit' => 'numeric|min:0',
        ];
    }
}
